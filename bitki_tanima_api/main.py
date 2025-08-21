import os
from fastapi import FastAPI, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from typing import Dict, Any

from api import predict_with_plantnet  # <-- helper modül

# AI (isteğe bağlı)
from openai import OpenAI
import json

load_dotenv()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

app = FastAPI(title="Plant ID API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],      # geliştirirken açık; prod'da kısıtla
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def _ai_enrich(data: Dict[str, Any], lang: str) -> Dict[str, Any]:
    """
    OpenAI varsa açıklamayı toparlayıp (lang’e göre) bakım önerileri + fun fact üret.
    Yoksa gelen raw açıklamayı döndür.
    """
    sci = data.get("scientific_name") or ""
    family = data.get("family") or ""
    common = ", ".join(data.get("common_names") or [])
    score = data.get("score")
    raw = data.get("description_raw") or data.get("description") or ""

    # OpenAI yok -> basit dönüş
    if not OPENAI_API_KEY:
        return {
            "description": raw,
            "care": [],
            "fun_fact": "",
            "ai_used": False,
            "ai_error": "",
        }

    client = OpenAI(api_key=OPENAI_API_KEY)

    sys_tr = (
        "Sen botanik konusunda uzman bir asistansın. "
        "Kısa, anlaşılır, abartısız yaz. "
        "Çıktıyı sadece JSON olarak ver: "
        '{"description":"...", "care":["...", "..."], "fun_fact":"..."}'
    )
    sys_en = (
        "You are a botany expert assistant. "
        "Write concise, clear, non-exaggerated text. "
        "Return JSON only: "
        '{"description":"...", "care":["...", "..."], "fun_fact":"..."}'
    )
    system = sys_tr if lang == "tr" else sys_en

    user_tr = (
        f"Bilimsel ad: {sci}\nAile: {family}\nYaygın adlar: {common}\n"
        f"Güven skoru: {round(score,2) if isinstance(score,(int,float)) else '-'}\n"
        f"Ham açıklama: {raw}\n"
        "Bu bitki için 1 paragraf açıklama, 3-5 maddelik bakım önerisi ve kısa bir fun fact üret. "
        "Sadece JSON ver."
    )
    user_en = (
        f"Scientific name: {sci}\nFamily: {family}\nCommon names: {common}\n"
        f"Confidence score: {round(score,2) if isinstance(score,(int,float)) else '-'}\n"
        f"Raw description: {raw}\n"
        "Produce one-paragraph description, 3–5 bullet care tips, and a short fun fact. Return JSON only."
    )
    user = user_tr if lang == "tr" else user_en

    try:
        resp = client.chat.completions.create(
            model="gpt-4o-mini",
            temperature=0.4,
            # JSON’a zorlamak daha güvenli:
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
        )
        content = resp.choices[0].message.content or "{}"
        parsed = json.loads(content)
        return {
            "description": (parsed.get("description") or raw),
            "care": parsed.get("care", []),
            "fun_fact": parsed.get("fun_fact", ""),
            "ai_used": True,
            "ai_error": "",
        }
    except Exception as e:
        # AI hata verirse ham veriye düş
        return {
            "description": raw,
            "care": [],
            "fun_fact": "",
            "ai_used": False,
            "ai_error": f"OpenAI error: {e}",
        }

@app.get("/")
def root():
    ok = bool(os.getenv("PLANTNET_API_KEY"))
    return {"status": "ok", "plantnet_key_loaded": ok}

@app.post("/predict")
async def predict(
    file: UploadFile = File(...),
    organ: str = Form("leaf"),
    lang: str = Form("tr")
):
    # 1) PlantNet’ten dinamik sonuç
    img = await file.read()
    base = predict_with_plantnet(img, organ, lang)

    # 2) AI (opsiyonel) ile zenginleştir
    enriched = _ai_enrich(base, lang)

    # 3) Birleştir ve mobilin beklediği tam şemayı dön
    return {
        "scientific_name": base.get("scientific_name"),
        "common_names": base.get("common_names", []),
        "score": base.get("score"),
        "family": base.get("family"),

        "description": enriched.get("description", base.get("description_raw", "")),
        "care": enriched.get("care", []),
        "fun_fact": enriched.get("fun_fact", ""),
        "ai_used": enriched.get("ai_used", False),
        "ai_error": enriched.get("ai_error", ""),

        "wikipedia_url": base.get("wikipedia_url", ""),
        "powo_url": base.get("powo_url", ""),
        "wikipedia_candidates": base.get("wikipedia_candidates", []),
        "powo_candidates": base.get("powo_candidates", []),
        "extra_images": base.get("extra_images", []),

        # istersen debug için geri bırak:
        "google_url": base.get("google_url", ""),
        "description_raw": base.get("description_raw", ""),
    }
