# api.py
# -----------------------------------------------------------
# Bu dosya FastAPI tabanlı basit bir arka uçtur.
# - /predict: resmi Pl@ntNet'e yollar, sonucu düzenler, (varsa) AI ile zenginleştirir.
# - /diag   : hızlı teşhis için; .env anahtarları geliyor mu, URL doğru mu görürüz.
# -----------------------------------------------------------

import os, json, re, requests
from typing import Dict, Any, List, Optional

from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
from requests.exceptions import HTTPError, ConnectionError, Timeout

# .env dosyasını oku (aynı klasörde olmalı)
load_dotenv()

# .env içinden anahtar ve proje adı
PLANTNET_API_KEY = os.getenv("PLANTNET_API_KEY")           # zorunlu
PLANTNET_PROJECT = os.getenv("PLANTNET_PROJECT", "all")    # genelde "all" kalır

# Pl@ntNet istek URL'si (ör: .../identify/all?api-key=XXXX)
PLANTNET_IDENTIFY_URL = (
    f"https://my-api.plantnet.org/v2/identify/{PLANTNET_PROJECT}?api-key={PLANTNET_API_KEY or ''}"
)

# --------- (Opsiyonel) OpenAI ve Ollama: açıklama/bakım notu üretmek için ---------
try:
    from openai import OpenAI
    _OA_KEY = os.getenv("OPENAI_API_KEY")  # varsa kullanırız; yoksa sorun değil
    openai_client: Optional[OpenAI] = OpenAI(api_key=_OA_KEY) if _OA_KEY else None
except Exception:
    openai_client = None

# Yerel ücretsiz LLM (Ollama) açık ise bundan da yararlanırız
OLLAMA_HOST  = os.getenv("OLLAMA_HOST", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3.1:8b")

# --------------------------- KÜÇÜK YARDIMCI FONKSİYONLAR ---------------------------

def _normalize_scientific_name(s: str) -> str:
    """Bilimsel ismi 'Genus species' şeklinde sadeleştirir (parantez vs. siler)."""
    if not s:
        return ""
    s = s.strip()
    s = re.sub(r"\(.*?\)", "", s).strip()
    parts = s.split()
    if len(parts) >= 2:
        return f"{parts[0]} {parts[1]}"
    return s

def _slugify_for_wiki(name: str) -> str:
    """Wiki URL için boşlukları _ yapar, gereksiz işaretleri temizler."""
    s = re.sub(r"\s+", " ", name.strip())
    s = re.sub(r"[\(\)\[\]\{\};:,]", "", s)
    return s.replace(" ", "_")

def _is_reachable(url: str, timeout: float = 5.0) -> bool:
    """URL ulaşılıyor mu? (HEAD isteği ile hızlı kontrol)"""
    try:
        h = requests.head(url, allow_redirects=True, timeout=timeout)
        return h.status_code < 400
    except Exception:
        return False

def _google_search_url(query: str, lang: str) -> str:
    """Google arama linki üretir (TR/EN arayüz)."""
    q = requests.utils.quote(query.strip())
    gl = "tr" if lang == "tr" else "en"
    hl = gl
    return f"https://www.google.com/search?q={q}&hl={hl}&gl={gl}"

def _wiki_candidates(scientific: str, common_names: List[str], lang: str) -> List[str]:
    """Olası Wikipedia sayfa URL'leri (bilimsel + yaygın adlardan)."""
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
    """Kew POWO arama linkleri (bilimsel + yaygın adlardan)."""
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
    """Aday URL’ler içinden erişilebilen ilkini seçer; yoksa None döner."""
    for u in urls:
        if _is_reachable(u):
            return u
    return None

# --------------------------- Pl@ntNet çağrısı ---------------------------

def _plantnet_identify(image_bytes: bytes, organ: str) -> Dict[str, Any]:
    """Görüntüyü Pl@ntNet'e gönderir; ham JSON sonucu döner."""
    if not PLANTNET_API_KEY:
        # .env içinde PLANTNET_API_KEY yoksa buraya düşer
        raise HTTPException(500, detail="PLANTNET_API_KEY tanımlı değil (.env).")

    files = [("images", ("image.jpg", image_bytes, "image/jpeg"))]
    data  = {"organs": organ or "leaf"}

    try:
        r = requests.post(PLANTNET_IDENTIFY_URL, files=files, data=data, timeout=40)
        r.raise_for_status()
        return r.json()

    # Aşağıdaki except blokları bize net teşhis verir:
    except HTTPError as e:
        status = e.response.status_code if e.response is not None else 500
        try:
            detail_json = e.response.json()
        except Exception:
            detail_json = {"error": e.response.text if e.response is not None else str(e)}
        msg = {"when": "plantnet_identify", "status": status, "detail": detail_json}
        print(f"[PLANTNET][HTTPError] {msg}")  # konsolda detay görünür
        raise HTTPException(status_code=status, detail=msg)

    except (ConnectionError, Timeout) as e:
        # İnternet/erişim sorunu (DNS, ağ, firewall…)
        print(f"[PLANTNET][NET] {type(e).__name__}: {e}")
        raise HTTPException(status_code=502, detail="Pl@ntNet'e ulaşılamıyor (bağlantı/timeout).")

    except Exception as e:
        # Beklenmeyen bir durum olursa
        print(f"[PLANTNET][UNEXPECTED] {e}")
        raise HTTPException(status_code=500, detail=f"Beklenmeyen hata: {e}")

# Pl@ntNet cevabını sade ve kullanışlı hale çeviriyoruz
def _map_plantnet_response(j: Dict[str, Any], lang: str) -> Dict[str, Any]:
    results: List[dict] = j.get("results") or []
    if not results:
        # Boşsa yine de front-end kırılmasın diye alanları döndürüyoruz
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

    # 2–3 sonucun küçük/orta görsellerini toplayalım (en fazla 6 adet)
    imgs = []
    for res in results[:3]:
        for im in (res.get("images") or []):
            u = (im.get("url") or {}).get("s") or (im.get("url") or {}).get("m")
            if u: imgs.append(u)
    extra_images = list(dict.fromkeys(imgs))[:6]

    # Basit bir açıklama cümlesi (AI yoksa bile ön tarafta dursun)
    raw_desc = (
        f"{sci} türü"
        f"{' (' + ', '.join(common_names) + ')' if common_names else ''} "
        f"{family or ''} familyasına aittir. Tahmin skoru: "
        f"{round(score, 2) if isinstance(score, (int, float)) else score}."
    )

    # Ziyaret edilebilecek bağlantılar
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
        "description": raw_desc,       # AI gelirse aşağıda üstüne yazarız
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

# --------------------------- AI ile zenginleştirme ---------------------------

def _enrich_with_ollama(payload: Dict[str, Any], lang: str) -> Dict[str, Any]:
    """Önce yerel Ollama’yı dene; varsa açıklama/bakım/fun fact üret."""
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
        # Ollama yoksa / kapalıysa sorun değil; OpenAI'ya bırakırız
        payload["ai_used"] = False
        payload["ai_error"] = f"Local AI error: {e}"
    return payload

def _enrich_with_openai(payload: Dict[str, Any], lang: str) -> Dict[str, Any]:
    """OpenAI anahtarı varsa ikinci şans olarak deneriz."""
    if openai_client is None:
        return payload
    prompt = (
        f"Sana bitki verisi veriyorum. Dilde cevapla: {('Türkçe' if lang=='tr' else 'English')}.\n"
        f"Bilimsel ad: {payload.get('scientific_name')}\n"
        f"Yaygın adlar: {', '.join(payload.get('common_names') or [])}\n"
        f"Aile: {payload.get('family')}\n"
        'Sadece JSON dön: {"description":"...","care":["..."],"fun_fact":"..."}'
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
    """Önce Ollama, olmazsa OpenAI ile zenginleştir."""
    enriched = _enrich_with_ollama(payload, lang)
    if enriched.get("ai_used"):
        return enriched
    return _enrich_with_openai(enriched, lang)

# --------------------------- FASTAPI KURULUMU ---------------------------

app = FastAPI(title="Bitki Tanıma API", version="1.4")

# Tüm origin'lere CORS izni ver (mobil/web rahat ulaşsın)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Sunucu açılırken konsola kısa bilgi bas
print(
    "[BOOT] PLANTNET_PROJECT=%s KEY=%s" %
    (
        PLANTNET_PROJECT,
        ("None" if not PLANTNET_API_KEY else PLANTNET_API_KEY[:4] + "…" + PLANTNET_API_KEY[-3:])
    )
)

@app.get("/")
def home():
    """Basit canlılık kontrolü."""
    return {"message": "API çalışıyor"}

@app.get("/diag")
def diag():
    """
    Hızlı teşhis:
    - api_key_present: .env dosyasından anahtar çekildi mi?
    - identify_url_prefix: İstek atılacak URL'nin başı
    """
    return {
        "project": PLANTNET_PROJECT,
        "api_key_present": bool(PLANTNET_API_KEY),
        "identify_url_prefix": PLANTNET_IDENTIFY_URL[:80] + "...",
    }

@app.post("/predict")
async def predict(
    file: UploadFile = File(...),         # form-data: file
    organ: str = Form("leaf"),            # form-data: organ (leaf/flower/fruit...)
    lang: str = Form("tr"),               # form-data: lang (tr/en)
):
    print(f"[API] /predict çağrısı organ='{organ}', lang='{lang}'")
    try:
        # 1) resmi belleğe oku
        image_bytes = await file.read()

        # 2) Pl@ntNet'e gönder ve ham sonucu al
        raw = _plantnet_identify(image_bytes, organ)

        # 3) Ham sonucu sadeleştir
        mapped = _map_plantnet_response(raw, lang)

        # 4) (Varsa) AI ile zenginleştir
        enriched = _enrich_with_ai(mapped, lang)

        print(f"[API] AI kullanıldı mı? {enriched.get('ai_used')}  Hata: {enriched.get('ai_error') or '-'}")
        return JSONResponse(enriched)

    # Yukarıdaki özel hataları olduğu gibi ilet
    except HTTPException as he:
        print(f"[API] HTTPException: {he.detail}")
        raise

    # Beklenmeyen genel bir şey olduysa 500 döndür
    except Exception as e:
        print(f"[API] 500: {e}")
        raise HTTPException(status_code=500, detail=str(e))
