# api.py
import os, io, json, re, requests
from typing import Dict, Any, List, Optional
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from dotenv import load_dotenv

load_dotenv()

PLANTNET_API_KEY = os.getenv("PLANTNET_API_KEY")
PLANTNET_PROJECT = os.getenv("PLANTNET_PROJECT", "all")

# --- OpenAI isteğe bağlı ---
try:
    from openai import OpenAI
    _OA_KEY = os.getenv("OPENAI_API_KEY")
    openai_client: Optional[OpenAI] = OpenAI(api_key=_OA_KEY) if _OA_KEY else None
except Exception:
    openai_client = None

# --- Ollama (yerel, ücretsiz) ---
OLLAMA_HOST  = os.getenv("OLLAMA_HOST", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3.1:8b")

# ================= Yardımcılar =================

def _normalize_scientific_name(s: str) -> str:
    if not s:
        return ""
    s = s.strip()
    s = re.sub(r"\(.*?\)", "", s).strip()
    parts = s.split()
    if len(parts) >= 2:
        return f"{parts[0]} {parts[1]}"
    return s

def _slugify_for_wiki(name: str) -> str:
    s = re.sub(r"\s+", " ", name.strip())
    s = re.sub(r"[\(\)\[\]\{\};:,]", "", s)
    return s.replace(" ", "_")

def _is_reachable(url: str, timeout: float = 5.0) -> bool:
    try:
        h = requests.head(url, allow_redirects=True, timeout=timeout)
        return h.status_code < 400
    except Exception:
        return False

def _google_search_url(query: str, lang: str) -> str:
    q = requests.utils.quote(query.strip())
    gl = "tr" if lang == "tr" else "en"
    hl = gl
    return f"https://www.google.com/search?q={q}&hl={hl}&gl={gl}"

def _wiki_candidates(scientific: str, common_names: List[str], lang: str) -> List[str]:
    base = "https://tr.wikipedia.org/wiki" if lang == "tr" else "https://en.wikipedia.org/wiki"
    sci_norm = _normalize_scientific_name(scientific)
    names: List[str] = []
    if sci_norm:
        names.append(sci_norm)
    names += (common_names or [])
    seen, cleaned = set(), []
    for n in names:
        n = (n or "").strip()
        if not n: 
            continue
        key = n.lower()
        if key in seen:
            continue
        seen.add(key)
        cleaned.append(n)
    return [f"{base}/{_slugify_for_wiki(n)}" for n in cleaned]

def _powo_candidates(scientific: str, common_names: List[str]) -> List[str]:
    sci_norm = _normalize_scientific_name(scientific)
    names: List[str] = []
    if sci_norm:
        names.append(sci_norm)
    names += (common_names or [])
    out = []
    for n in names:
        n = (n or "").strip()
        if not n:
            continue
        out.append(f"https://powo.science.kew.org/?q={requests.utils.quote(n)}")
    return out

def _pick_primary(urls: List[str]) -> Optional[str]:
    for u in urls:
        if _is_reachable(u):
            return u
    return None

# ================= Pl@ntNet =================

def _plantnet_identify(image_bytes: bytes, organ: str) -> Dict[str, Any]:
    if not PLANTNET_API_KEY:
        raise HTTPException(500, detail="PLANTNET_API_KEY tanımlı değil (.env).")

    url = f"https://my-api.plantnet.org/v2/identify/{PLANTNET_PROJECT}?api-key={PLANTNET_API_KEY}"
    files = [("images", ("image.jpg", image_bytes, "image/jpeg"))]
    data  = {"organs": organ or "leaf"}

    r = requests.post(url, files=files, data=data, timeout=40)
    r.raise_for_status()
    return r.json()

def _map_plantnet_response(j: Dict[str, Any], lang: str) -> Dict[str, Any]:
    results: List[dict] = j.get("results") or []
    if not results:
        return {
            "scientific_name": "",
            "score": None,
            "common_names": [],
            "family": None,
            "description": "",
            "description_raw": "",
            "wikipedia_url": "",
            "powo_url": "",
            "google_url": "",
            "wikipedia_candidates": [],
            "powo_candidates": [],
            "extra_images": [],
            "care": [],
            "fun_fact": "",
            "ai_used": False,
            "ai_error": "",
        }

    best = results[0]
    score = best.get("score")
    species = best.get("species") or {}
    sci = species.get("scientificName") or ""
    family = (species.get("family") or {}).get("scientificName")
    common_names = species.get("commonNames") or []

    imgs = []
    for res in results[:3]:
        for im in (res.get("images") or []):
            u = (im.get("url") or {}).get("s") or (im.get("url") or {}).get("m")
            if u: imgs.append(u)
    extra_images = list(dict.fromkeys(imgs))[:6]

    raw_desc = (
        f"{sci} türü"
        f"{' (' + ', '.join(common_names) + ')' if common_names else ''} "
        f"{family or ''} familyasına aittir. Tahmin skoru: "
        f"{round(score, 2) if isinstance(score, (int, float)) else score}."
    )

    wiki_cands = _wiki_candidates(sci, common_names, lang)
    powo_cands = _powo_candidates(sci, common_names)

    query_for_google = _normalize_scientific_name(sci) or (common_names[0] if common_names else "")
    google_url = _google_search_url(query_for_google, lang) if query_for_google else ""

    wiki_primary = _pick_primary(wiki_cands) or google_url
    powo_primary = _pick_primary(powo_cands) or google_url

    return {
        "scientific_name": sci,
        "score": score,
        "common_names": common_names,
        "family": family,
        "description": raw_desc,
        "description_raw": raw_desc,
        "wikipedia_url": wiki_primary,
        "powo_url": powo_primary,
        "google_url": google_url,
        "wikipedia_candidates": wiki_cands,
        "powo_candidates": powo_cands,
        "extra_images": extra_images,
        "care": [],
        "fun_fact": "",
        "ai_used": False,
        "ai_error": "",
    }

# ================= AI =================

def _enrich_with_ollama(payload: Dict[str, Any], lang: str) -> Dict[str, Any]:
    prompt = (
        f"Dil: {'Türkçe' if lang=='tr' else 'English'}.\n"
        f"Scientific name: {payload.get('scientific_name')}\n"
        f"Common names: {', '.join(payload.get('common_names') or [])}\n"
        f"Family: {payload.get('family')}\n\n"
        "Write a JSON with keys:\n"
        "description: 1 short natural paragraph about what it is, native range/habitat and basic light/water needs,\n"
        "care: 3-5 concise care tips as a list,\n"
        "fun_fact: one sentence fun fact.\n"
        "Return ONLY JSON."
    )
    try:
        r = requests.post(
            f"{OLLAMA_HOST}/api/generate",
            json={"model": OLLAMA_MODEL, "prompt": prompt, "stream": False, "options": {"temperature": 0.7}},
            timeout=120,
        )
        r.raise_for_status()
        txt = r.json().get("response", "{}")
        j = json.loads(txt)

        desc = (j.get("description") or "").strip()
        care = j.get("care") or []
        fun  = (j.get("fun_fact") or "").strip()

        if desc: payload["description"] = desc
        if isinstance(care, list): payload["care"] = [str(x) for x in care][:6]
        if fun: payload["fun_fact"] = fun

        payload["ai_used"] = True
        payload["ai_error"] = ""
    except Exception as e:
        payload["ai_used"] = False
        payload["ai_error"] = f"Local AI error: {e}"
    return payload

def _enrich_with_openai(payload: Dict[str, Any], lang: str) -> Dict[str, Any]:
    if openai_client is None:
        return payload
    prompt = (
        f"Sana bitki verisi veriyorum. Dilde cevapla: {('Türkçe' if lang=='tr' else 'English')}.\n"
        f"Bilimsel ad: {payload.get('scientific_name')}\n"
        f"Yaygın adlar: {', '.join(payload.get('common_names') or [])}\n"
        f"Aile: {payload.get('family')}\n"
        "Sadece JSON dön: {\"description\":\"...\",\"care\":[\"...\"],\"fun_fact\":\"...\"}"
    )
    try:
        resp = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            temperature=0.7,
            messages=[
                {"role": "system", "content": "You are a helpful horticulture assistant."},
                {"role": "user", "content": prompt},
            ],
            response_format={"type": "json_object"},
        )
        j = json.loads(resp.choices[0].message.content or "{}")
        if j.get("description"): payload["description"] = j["description"].strip()
        if isinstance(j.get("care"), list): payload["care"] = [str(x) for x in j["care"]][:6]
        if j.get("fun_fact"): payload["fun_fact"] = j["fun_fact"].strip()
        payload["ai_used"] = True
        payload["ai_error"] = ""
    except Exception as e:
        payload["ai_used"] = False
        payload["ai_error"] = f"OpenAI error: {e}"
    return payload

def _enrich_with_ai(payload: Dict[str, Any], lang: str) -> Dict[str, Any]:
    enriched = _enrich_with_ollama(payload, lang)
    if enriched.get("ai_used"):
        return enriched
    return _enrich_with_openai(enriched, lang)

# ================= FastAPI =================

app = FastAPI(title="Bitki Tanıma API", version="1.3")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],    # düzeltildi
    allow_headers=["*"],    # düzeltildi
)

@app.get("/")
def home():
    return {"message": "API çalışıyor"}

@app.post("/predict")
async def predict(
    file: UploadFile = File(...),
    organ: str = Form("leaf"),
    lang: str = Form("tr"),
):
    print(f"[API] /predict çağrısı organ='{organ}', lang='{lang}'")
    try:
        image_bytes = await file.read()
        raw = _plantnet_identify(image_bytes, organ)
        mapped = _map_plantnet_response(raw, lang)
        enriched = _enrich_with_ai(mapped, lang)
        print(f"[API] AI kullanıldı mı? {enriched.get('ai_used')}  Hata: {enriched.get('ai_error') or '-'}")
        return JSONResponse(enriched)
    except HTTPException as he:
        print(f"[API] HTTPException: {he.detail}")
        raise he
    except requests.HTTPError as re:
        print(f"[API] RequestsHTTPError: {re}")
        raise HTTPException(status_code=re.response.status_code, detail=str(re))
    except Exception as e:
        print(f"[API] 500: {e}")
        raise HTTPException(status_code=500, detail=str(e))
