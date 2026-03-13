"""
Hugging Face Spaces-ready FastAPI app for fake news detection.

How to use:
1) Export your fine-tuned model from Colab:

    model.save_pretrained("./model")
    tokenizer.save_pretrained("./model")

2) Place the exported folder as ./model next to this file.
3) Install requirements and run:

    uvicorn newmodel:app --host 0.0.0.0 --port 7860

Environment variables:
- MODEL_NAME_OR_PATH (default: ./model)
- MODEL_VERSION (default: roberta-finetuned-v1)
- MAX_LENGTH (default: 384)
- FAKE_LABEL_ID (default: 0)
- REAL_LABEL_ID (default: 1)
"""

from __future__ import annotations

import os
from typing import Optional

import torch
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from transformers import AutoModelForSequenceClassification, AutoTokenizer

# -------------------------------------
# Configuration
# -------------------------------------
MODEL_NAME_OR_PATH = os.getenv("MODEL_NAME_OR_PATH", "./model")
MODEL_VERSION = os.getenv("MODEL_VERSION", "roberta-finetuned-v1")
MAX_LENGTH = int(os.getenv("MAX_LENGTH", "384"))

# Based on your training notebook labels:
# 0 = FAKE, 1 = REAL
FAKE_LABEL_ID = int(os.getenv("FAKE_LABEL_ID", "0"))
REAL_LABEL_ID = int(os.getenv("REAL_LABEL_ID", "1"))

# -------------------------------------
# App
# -------------------------------------
app = FastAPI(
    title="Fake News Detection API (RoBERTa)",
    description="RoBERTa sequence classification service for fake news detection",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -------------------------------------
# Global model state
# -------------------------------------
model: Optional[AutoModelForSequenceClassification] = None
tokenizer: Optional[AutoTokenizer] = None
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")


class PredictionRequest(BaseModel):
    text: str


class PredictionResponse(BaseModel):
    result: str
    confidence: float
    model_version: str
    fake_probability: float
    real_probability: float


@app.on_event("startup")
async def load_model_artifacts() -> None:
    """Load tokenizer and model from local folder or HF repo path."""
    global model, tokenizer

    try:
        print(f"Loading artifacts from: {MODEL_NAME_OR_PATH}")
        tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME_OR_PATH)
        model = AutoModelForSequenceClassification.from_pretrained(MODEL_NAME_OR_PATH)
        model.to(device)
        model.eval()
        print(f"Model loaded successfully on {device}")
    except Exception as exc:
        print(f"Failed to load artifacts: {exc}")
        model = None
        tokenizer = None


@app.get("/")
def root() -> dict:
    return {
        "name": "Fake News Detection API (RoBERTa)",
        "version": "1.0.0",
        "model_loaded": model is not None,
        "tokenizer_loaded": tokenizer is not None,
        "model_name_or_path": MODEL_NAME_OR_PATH,
        "device": str(device),
        "endpoints": {
            "GET /health": "Health check",
            "POST /predict": "Fake/real prediction",
        },
    }


@app.get("/health")
def health_check() -> dict:
    if model is None or tokenizer is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    return {
        "status": "healthy",
        "model_loaded": True,
        "tokenizer_loaded": True,
        "device": str(device),
        "model_version": MODEL_VERSION,
    }


@app.post("/predict", response_model=PredictionResponse)
def predict(request: PredictionRequest) -> PredictionResponse:
    if model is None or tokenizer is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    text = request.text.strip() if request.text else ""
    if not text:
        raise HTTPException(status_code=400, detail="Text cannot be empty")

    try:
        inputs = tokenizer(
            [text],
            truncation=True,
            padding=True,
            max_length=MAX_LENGTH,
            return_tensors="pt",
        )
        inputs = {k: v.to(device) for k, v in inputs.items()}

        with torch.no_grad():
            outputs = model(**inputs)
            probs = torch.softmax(outputs.logits, dim=-1)[0]

        fake_prob = float(probs[FAKE_LABEL_ID].item())
        real_prob = float(probs[REAL_LABEL_ID].item())

        if fake_prob >= real_prob:
            result = "FAKE"
            confidence = fake_prob
        else:
            result = "REAL"
            confidence = real_prob

        return PredictionResponse(
            result=result,
            confidence=round(confidence, 4),
            model_version=MODEL_VERSION,
            fake_probability=round(fake_prob, 4),
            real_probability=round(real_prob, 4),
        )
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {exc}")


if __name__ == "__main__":
    port = int(os.getenv("PORT", "7860"))
    uvicorn.run(app, host="0.0.0.0", port=port)