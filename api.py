# api.py
# -----------------------------------------------------------
# FastAPI tabanlı tek dosya backend:
# - /diag   : .env okundu mu? hedef URL ne? hızlı teşhis
# - /predict: resmi Pl@ntNet'e yollar, sonucu sadeleştirir,
#             (varsa) OpenAI ile açıklama/bakım notu ekler.
# -----------------------------------------------------------

import os, json, re, requests
from typing import Dict, Any, List, Optional

from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# ⬇⬇⬇  YENİ: .env'yi bu dosyayla AYNI klasörden, ezerek yükle
from pathlib import Path
from dotenv import load_dotenv
#ENV_PATH = Path(__file__).with_name(".env")
#load_dotenv(dotenv_path=ENV_PATH, override=True)
# ⬆⬆⬆


# .env içinden anahtar/proje
PLANTNET_API_KEY = "2b107Q00sDEds4TO3EkVpJTHN"           # ZORUNLU
PLANTNET_PROJECT = os.getenv("PLANTNET_PROJECT", "all")      # genelde "all"
OPENAI_API_KEY    = os.getenv("OPENAI_API_KEY")              # opsiyonel

# Pl@ntNet endpoint (ör: .../identify/all?api-key=XXXX)
PLANTNET_IDENTIFY_URL = f"https://my-api.plantnet.org/v2/identify/{PLANTNET_PROJECT}?api-key={PLANTNET_API_KEY or ''}"

# --------- (Opsiyonel) OpenAI: açıklama/bakım/fun fact üretmek için ---------
try:
    from openai import OpenAI
    openai_client: Optional[OpenAI] = OpenAI(api_key=OPENAI_API_KEY) if OPENAI_API_KEY else None
except Exception:
    openai_client = None

# ------------------------ Yardımcılar (basit ve anlaşılır) ------------------------

def _normalize_scientific_name(s: str) -> str:
    """Bilimsel ismi 'Genus species' şeklinde sadeleştir (parantez vs. sil)."""
    if not s:
        return ""
    s = s.strip()
    s = re.sub(r"\(.*?\)", "", s).strip()
    parts = s.split()
    if len(parts) >= 2:
        return f"{parts[0]} {parts[1]}"
    return s

def _slugify_for_wiki(name: str) -> str:
    """Wiki URL için boşlukları '_' yap, gereksiz işaretleri temizle."""
    s = re.sub(r"\s+", " ", name.strip())
    s = re.sub(r"[\(\)\[\]\{\};:,]", "", s)
    return s.replace(" ", "_")

def _is_reachable(url: str, timeout: float = 5.0) -> bool:
    """URL erişilebilir mi? (HEAD ile hızlı kontrol)"""
    try:
        h = requests.head(url, allow_redirects=True, timeout=timeout)
        return h.status_code < 400
    except Exception:
        return False

def _google_search_url(query: str, lang: str) -> str:
    """Google arama linki (TR/EN arayüz)."""
    q = requests.utils.quote((query or "").strip())
    gl = "tr" if lang == "tr" else "en"
    hl = gl
    return f"https://www.google.com/search?q={q}&hl={hl}&gl={gl}"

def _wiki_candidates(scientific: str, common_names: List[str], lang: str) -> List[str]:
    """Muhtemel Wikipedia sayfaları (bilimsel + yaygın adlardan)."""
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
    """Kew POWO arama linkleri."""
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
    """Aday URL’ler içinden erişilebilen ilkini seç, yoksa None."""
    for u in urls:
        if _is_reachable(u):
            return u
    return None

# --------------------------- Pl@ntNet çağrısı ---------------------------

def _plantnet_identify(image_bytes: bytes, organ: str) -> Dict[str, Any]:
    """Görüntüyü Pl@ntNet'e gönder, ham JSON’u döndür."""
    if not PLANTNET_API_KEY:
        raise HTTPException(500, detail="PLANTNET_API_KEY tanımlı değil (.env).")

    files = [("images", ("image.jpg", image_bytes, "image/jpeg"))]
    data  = {"organs": organ or "leaf"}

    try:
        r = requests.post(PLANTNET_IDENTIFY_URL, files=files, data=data, timeout=40)
        r.raise_for_status()
        return r.json()

    except HTTPError as e:
        status = e.response.status_code if e.response is not None else 500
        try:
            detail_json = e.response.json()
        except Exception:
            detail_json = {"error": e.response.text if e.response is not None else str(e)}
        msg = {"when": "plantnet_identify", "status": status, "detail": detail_json}
        print(f"[PLANTNET][HTTPError] {msg}")
        raise HTTPException(status_code=status, detail=msg)

    except (ConnectionError, Timeout) as e:
        print(f"[PLANTNET][NET] {type(e).__name__}: {e}")
        raise HTTPException(status_code=502, detail="Pl@ntNet'e ulaşılamıyor (bağlantı/timeout).")

    except Exception as e:
        print(f"[PLANTNET][UNEXPECTED] {e}")
        raise HTTPException(status_code=500, detail=f"Beklenmeyen hata: {e}")

def _map_plantnet_response(j: Dict[str, Any], lang: str) -> Dict[str, Any]:
    """Pl@ntNet ham cevabını, Flutter’ın beklediği basit şemaya çevir."""
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

    # Küçük/orta görsellerden en fazla 6 tane
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
        "description": raw_desc,       # AI gelirse üzerine yazacağız
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

# --------------------------- AI ile zenginleştirme (opsiyonel) ---------------------------

def _ai_enrich_openai(payload: Dict[str, Any], lang: str) -> Dict[str, Any]:
    """
    OPENAI_API_KEY varsa kısa açıklama + 3-5 bakım önerisi + fun fact üretir.
    Yoksa olduğu gibi döner (ai_used=False).
    """
    if openai_client is None:
        return {**payload, "ai_used": False, "ai_error": ""}

    sci = payload.get("scientific_name") or ""
    family = payload.get("family") or ""
    common = ", ".join(payload.get("common_names") or [])
    score = payload.get("score")
    raw   = payload.get("description_raw") or payload.get("description") or ""

    sys_tr = ("Sen botanik konusunda uzman bir asistansın. Kısa, anlaşılır yaz. "
              'JSON olarak dön: {"description":"...", "care":["..."], "fun_fact":"..."}')
    sys_en = ("You are a botany expert assistant. Be concise and clear. "
              'Return JSON: {"description":"...", "care":["..."], "fun_fact":"..."}')
    system = sys_tr if lang == "tr" else sys_en

    user_tr = (
        f"Bilimsel ad: {sci}\nAile: {family}\nYaygın adlar: {common}\n"
        f"Güven skoru: {round(score,2) if isinstance(score,(int,float)) else '-'}\n"
        f"Ham açıklama: {raw}\n"
        "1 paragraf açıklama, 3-5 maddelik bakım önerisi ve kısa fun fact üret. Sadece JSON ver."
    )
    user_en = (
        f"Scientific name: {sci}\nFamily: {family}\nCommon names: {common}\n"
        f"Confidence score: {round(score,2) if isinstance(score,(int,float)) else '-'}\n"
        f"Raw description: {raw}\n"
        "Return one-paragraph description, 3–5 bullet care tips, and a short fun fact. JSON only."
    )
    user = user_tr if lang == "tr" else user_en

    try:
        resp = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            temperature=0.4,
            response_format={"type": "json_object"},  # JSON’a zorla
            messages=[
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
        )
        content = resp.choices[0].message.content or "{}"
        parsed = json.loads(content)

        payload["description"] = (parsed.get("description") or raw).strip()
        payload["care"]        = [str(x) for x in (parsed.get("care") or [])][:6]
        payload["fun_fact"]    = (parsed.get("fun_fact") or "").strip()
        payload["ai_used"]     = True
        payload["ai_error"]    = ""
    except Exception as e:
        payload["ai_used"]  = False
        payload["ai_error"] = f"OpenAI error: {e}"
    return payload

# --------------------------- FastAPI kurulum & uçlar ---------------------------

app = FastAPI(title="Bitki Tanıma API", version="1.5")

# CORS (web/mobil erişsin)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # geliştirme için açık; prod'da kısıtla
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("[BOOT] PROJECT=%s KEY=%s" % (
    PLANTNET_PROJECT,
    ("None" if not PLANTNET_API_KEY else PLANTNET_API_KEY[:4] + "…" + PLANTNET_API_KEY[-3:])
))

@app.get("/")
def root():
    """Basit canlılık kontrolü."""
    return {"status": "ok", "plantnet_key_loaded": bool(PLANTNET_API_KEY)}

@app.get("/diag")
def diag():
    """Hızlı teşhis: anahtar geldi mi, URL nasıl görünüyor?"""
    return {
        "project": PLANTNET_PROJECT,
        "api_key_present": bool(PLANTNET_API_KEY),
        "identify_url_prefix": PLANTNET_IDENTIFY_URL[:80] + "...",
        "openai_present": bool(OPENAI_API_KEY),
    }

@app.post("/predict")
async def predict(
    file: UploadFile = File(...),   # form-data: file
    organ: str = Form("leaf"),      # form-data: organ (leaf/flower/fruit...)
    lang: str = Form("tr"),         # form-data: lang (tr/en)
):
    print(f"[API] /predict organ='{organ}' lang='{lang}'")
    try:
        img = await file.read()                        # 1) resmi oku
        raw = _plantnet_identify(img, organ)           # 2) PlantNet
        base = _map_plantnet_response(raw, lang)       # 3) sadeleştir
        full = _ai_enrich_openai(base, lang)           # 4) (ops.) AI
        return JSONResponse(full)

    except HTTPException as he:
        print(f"[API] HTTPException: {he.detail}")
        raise
    except Exception as e:
        print(f"[API] 500: {e}")
        raise HTTPException(status_code=500, detail=str(e))
