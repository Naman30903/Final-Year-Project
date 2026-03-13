"""
Fake News Detection API — RoBERTa fine-tuned.

Deployment targets
──────────────────
• Hugging Face Spaces  (uvicorn newmodel:app --host 0.0.0.0 --port 7860)
• Local / Docker       (same command, or python newmodel.py)

Environment variables
─────────────────────
MODEL_NAME_OR_PATH  – HF repo ID or local ./model dir  (default: ./model)
MODEL_VERSION       – free-text label returned in responses
MAX_LENGTH          – tokeniser truncation length       (default: 384)
FAKE_LABEL_ID       – class index for FAKE              (default: 0)
REAL_LABEL_ID       – class index for REAL              (default: 1)
SCRAPE_TIMEOUT      – seconds to wait when fetching URLs (default: 15)

Web-scraping support
────────────────────
POST /predict        { "text": "..." }          — plain text
POST /predict/url    { "url":  "https://..." }  — article URL (scraped here)
"""

from __future__ import annotations

import os
import re
from typing import Optional
from urllib.parse import urlparse

import httpx
import torch
import uvicorn
from bs4 import BeautifulSoup
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, HttpUrl
from transformers import AutoModelForSequenceClassification, AutoTokenizer

# ──────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────
MODEL_NAME_OR_PATH = os.getenv("MODEL_NAME_OR_PATH", "./model")
MODEL_VERSION      = os.getenv("MODEL_VERSION",      "roberta-finetuned-v1")
MAX_LENGTH         = int(os.getenv("MAX_LENGTH",     "384"))
FAKE_LABEL_ID      = int(os.getenv("FAKE_LABEL_ID",  "0"))
REAL_LABEL_ID      = int(os.getenv("REAL_LABEL_ID",  "1"))
SCRAPE_TIMEOUT     = int(os.getenv("SCRAPE_TIMEOUT", "15"))

# ──────────────────────────────────────────────
# FastAPI app
# ──────────────────────────────────────────────
app = FastAPI(
    title="Fake News Detection API",
    description="RoBERTa-based fake news detection with optional URL scraping.",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ──────────────────────────────────────────────
# Global model state
# ──────────────────────────────────────────────
_model: Optional[AutoModelForSequenceClassification] = None
_tokenizer: Optional[AutoTokenizer] = None
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")


# ──────────────────────────────────────────────
# Pydantic schemas
# ──────────────────────────────────────────────
class TextRequest(BaseModel):
    text: str


class UrlRequest(BaseModel):
    url: HttpUrl


class PredictionResponse(BaseModel):
    result: str
    confidence: float
    model_version: str
    fake_probability: float
    real_probability: float
    source_url: Optional[str] = None
    extracted_text_preview: Optional[str] = None  # first 300 chars for debugging


# ──────────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────────
@app.on_event("startup")
async def load_model_artifacts() -> None:
    global _model, _tokenizer
    try:
        print(f"[startup] Loading from: {MODEL_NAME_OR_PATH}")
        _tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME_OR_PATH)
        _model = AutoModelForSequenceClassification.from_pretrained(MODEL_NAME_OR_PATH)
        _model.to(device)
        _model.eval()
        print(f"[startup] Model ready on {device}")
    except Exception as exc:
        print(f"[startup] ERROR – could not load model: {exc}")
        _model = None
        _tokenizer = None


# ──────────────────────────────────────────────
# Scraping helpers
# ──────────────────────────────────────────────
# Tags whose text we never want (nav, ads, footers …)
_NOISE_TAGS = {"script", "style", "nav", "header", "footer", "aside",
               "noscript", "form", "button", "iframe", "figure"}

# Domains that block bots aggressively — we surface a clear error instead of
# returning garbage text.
_BLOCKED_DOMAINS = {"twitter.com", "x.com", "instagram.com", "facebook.com",
                    "tiktok.com", "linkedin.com"}

_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/123.0 Safari/537.36"
    ),
    "Accept-Language": "en-US,en;q=0.9",
}


def _extract_article_text(html: str) -> str:
    """
    Heuristic article extractor (no external NLP dependency).

    Strategy:
    1. Try <article> tag — most news sites wrap body copy there.
    2. Fall back to the <div> / <section> with the most <p> children.
    3. If still thin, concatenate all <p> text across the page.
    """
    soup = BeautifulSoup(html, "html.parser")

    # Remove noise tags
    for tag in soup(_NOISE_TAGS):
        tag.decompose()

    def _paragraphs(node) -> list[str]:
        return [p.get_text(" ", strip=True)
                for p in node.find_all("p")
                if len(p.get_text(strip=True)) > 40]

    # 1. <article>
    article_tag = soup.find("article")
    if article_tag:
        paras = _paragraphs(article_tag)
        if paras:
            return " ".join(paras)

    # 2. Best <div> / <section> by paragraph count
    best_node, best_count = None, 0
    for container in soup.find_all(["div", "section"]):
        count = len(_paragraphs(container))
        if count > best_count:
            best_count = count
            best_node = container

    if best_node and best_count >= 3:
        paras = _paragraphs(best_node)
        return " ".join(paras)

    # 3. All <p> tags
    paras = [p.get_text(" ", strip=True)
             for p in soup.find_all("p")
             if len(p.get_text(strip=True)) > 40]
    return " ".join(paras)


async def scrape_article(url: str) -> str:
    """Fetch *url* and return clean article text (raises HTTPException on failure)."""
    hostname = urlparse(url).hostname or ""
    if any(blocked in hostname for blocked in _BLOCKED_DOMAINS):
        raise HTTPException(
            status_code=422,
            detail=f"Domain '{hostname}' blocks automated scraping. "
                   "Please paste the article text directly via POST /predict."
        )

    try:
        async with httpx.AsyncClient(
            follow_redirects=True,
            timeout=SCRAPE_TIMEOUT,
            headers=_HEADERS,
        ) as client:
            resp = await client.get(url)
            resp.raise_for_status()
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail=f"Timed out fetching URL: {url}")
    except httpx.HTTPStatusError as exc:
        raise HTTPException(
            status_code=502,
            detail=f"URL returned HTTP {exc.response.status_code}"
        )
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Could not fetch URL: {exc}")

    content_type = resp.headers.get("content-type", "")
    if "html" not in content_type:
        raise HTTPException(
            status_code=422,
            detail=f"URL did not return HTML (got: {content_type}). "
                   "Only news article web pages are supported."
        )

    text = _extract_article_text(resp.text)

    # Clean up whitespace
    text = re.sub(r"\s{2,}", " ", text).strip()

    if len(text) < 100:
        raise HTTPException(
            status_code=422,
            detail=(
                "Could not extract enough article text from the page "
                f"(got {len(text)} chars). The site may use JavaScript rendering. "
                "Please paste the article text via POST /predict."
            ),
        )

    return text


# ──────────────────────────────────────────────
# Inference helper
# ──────────────────────────────────────────────
def _run_inference(text: str) -> tuple[str, float, float, float]:
    """Returns (result, confidence, fake_prob, real_prob)."""
    if _model is None or _tokenizer is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    inputs = _tokenizer(
        [text],
        truncation=True,
        padding=True,
        max_length=MAX_LENGTH,
        return_tensors="pt",
    )
    inputs = {k: v.to(device) for k, v in inputs.items()}

    with torch.no_grad():
        outputs = _model(**inputs)
        probs = torch.softmax(outputs.logits, dim=-1)[0]

    fake_prob = float(probs[FAKE_LABEL_ID].item())
    real_prob = float(probs[REAL_LABEL_ID].item())

    if fake_prob >= real_prob:
        return "FAKE", fake_prob, fake_prob, real_prob
    return "REAL", real_prob, fake_prob, real_prob


# ──────────────────────────────────────────────
# Routes
# ──────────────────────────────────────────────
@app.get("/")
def root() -> dict:
    return {
        "name": "Fake News Detection API",
        "version": "2.0.0",
        "model_loaded": _model is not None,
        "device": str(device),
        "endpoints": {
            "GET  /health":      "Liveness / readiness check",
            "POST /predict":     "Predict from raw text  { text: str }",
            "POST /predict/url": "Predict from article URL  { url: str }",
        },
    }


@app.get("/health")
def health_check() -> dict:
    if _model is None or _tokenizer is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    return {
        "status": "healthy",
        "model_version": MODEL_VERSION,
        "device": str(device),
    }


@app.post("/predict", response_model=PredictionResponse)
def predict_text(request: TextRequest) -> PredictionResponse:
    """Classify raw article text."""
    text = request.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="text cannot be empty")

    try:
        result, confidence, fake_prob, real_prob = _run_inference(text)
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {exc}")

    return PredictionResponse(
        result=result,
        confidence=round(confidence, 4),
        model_version=MODEL_VERSION,
        fake_probability=round(fake_prob, 4),
        real_probability=round(real_prob, 4),
    )


@app.post("/predict/url", response_model=PredictionResponse)
async def predict_url(request: UrlRequest) -> PredictionResponse:
    """
    Scrape an article URL and classify it.

    Accepts any publicly accessible news article URL.
    Returns the prediction plus a short preview of the extracted text.
    """
    url = str(request.url)
    text = await scrape_article(url)

    try:
        result, confidence, fake_prob, real_prob = _run_inference(text)
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {exc}")

    return PredictionResponse(
        result=result,
        confidence=round(confidence, 4),
        model_version=MODEL_VERSION,
        fake_probability=round(fake_prob, 4),
        real_probability=round(real_prob, 4),
        source_url=url,
        extracted_text_preview=text[:300],
    )


# ──────────────────────────────────────────────
if __name__ == "__main__":
    port = int(os.getenv("PORT", "7860"))
    uvicorn.run(app, host="0.0.0.0", port=port)
