"""
FastAPI ML Service for Fake News Detection
Deploy to Hugging Face Spaces or Render

Usage:
1. Place model_fold1.h5 and tokenizer.pkl in the same directory
2. pip install -r requirements.txt
3. python app.py (or uvicorn app:app --reload)
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import tensorflow as tf
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing.sequence import pad_sequences
import pickle
import numpy as np
import re
import os
import uvicorn

# ============== Configuration ==============
MAX_LENGTH = 300
MODEL_PATH = "model_fold1.h5"
TOKENIZER_PATH = "tokenizer.pkl"

# ============== FastAPI App ==============
app = FastAPI(
    title="Fake News Detection API",
    description="Kaggle-trained deep learning model for fake news detection",
    version="1.0.0"
)

# CORS - Allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============== Global Model & Tokenizer ==============
model = None
tokenizer = None

# ============== Request/Response Models ==============
class PredictionRequest(BaseModel):
    text: str

class PredictionResponse(BaseModel):
    result: str
    confidence: float
    model_version: str
    fake_probability: float
    real_probability: float

# ============== Text Cleaning (same as training) ==============
def clean_text(text: str) -> str:
    """Clean text exactly as during training"""
    text = str(text).lower()
    
    # Remove Reuters tags and location markers (prevent data leakage)
    text = re.sub(r'\(reuters\)', '', text, flags=re.IGNORECASE)
    text = re.sub(r'(washington|london|moscow|new york|beijing) -', '', text, flags=re.IGNORECASE)
    
    # Remove URLs
    text = re.sub(r'http\S+|www\S+', '', text)
    
    # Remove email addresses
    text = re.sub(r'\S+@\S+', '', text)
    
    # Keep letters, numbers, and spaces
    text = re.sub(r'[^a-zA-Z0-9\s]', '', text)
    
    # Remove extra whitespace
    text = ' '.join(text.split())
    
    return text

# ============== Startup: Load Model ==============
@app.on_event("startup")
async def load_model_and_tokenizer():
    """Load model and tokenizer on startup"""
    global model, tokenizer
    
    print("🚀 Loading model artifacts...")
    
    # Check if files exist
    if not os.path.exists(MODEL_PATH):
        print(f"❌ Model not found at {MODEL_PATH}")
        print("   Please place model_fold1.h5 in the same directory")
        return
    
    if not os.path.exists(TOKENIZER_PATH):
        print(f"❌ Tokenizer not found at {TOKENIZER_PATH}")
        print("   Please place tokenizer.pkl in the same directory")
        return
    
    try:
        # Load model
        model = load_model(MODEL_PATH)
        print(f"✅ Model loaded from {MODEL_PATH}")
        
        # Load tokenizer
        with open(TOKENIZER_PATH, 'rb') as f:
            tokenizer = pickle.load(f)
        print(f"✅ Tokenizer loaded from {TOKENIZER_PATH}")
        
        print("🎉 ML Service ready!")
        
    except Exception as e:
        print(f"❌ Error loading model: {e}")
        model = None
        tokenizer = None

# ============== Endpoints ==============
@app.get("/")
def root():
    """Root endpoint with API info"""
    return {
        "name": "Fake News Detection API",
        "version": "1.0.0",
        "model_loaded": model is not None,
        "tokenizer_loaded": tokenizer is not None,
        "endpoints": {
            "POST /predict": "Analyze text for fake news",
            "GET /health": "Health check"
        }
    }

@app.get("/health")
def health_check():
    """Health check endpoint"""
    if model is None or tokenizer is None:
        raise HTTPException(
            status_code=503,
            detail="Model not loaded. Please check server logs."
        )
    
    return {
        "status": "healthy",
        "model_loaded": True,
        "tokenizer_loaded": True
    }

@app.post("/predict", response_model=PredictionResponse)
def predict(request: PredictionRequest):
    """
    Predict if news article is fake or real
    
    - **text**: The news article text to analyze
    """
    # Check if model is loaded
    if model is None or tokenizer is None:
        raise HTTPException(
            status_code=503,
            detail="Model not loaded. Please restart the server with model files."
        )
    
    # Validate input
    if not request.text or len(request.text.strip()) == 0:
        raise HTTPException(
            status_code=400,
            detail="Text cannot be empty"
        )
    
    try:
        # Clean text (same as training)
        cleaned = clean_text(request.text)
        
        # Tokenize
        sequences = tokenizer.texts_to_sequences([cleaned])
        
        # Pad
        padded = pad_sequences(
            sequences,
            maxlen=MAX_LENGTH,
            padding='post',
            truncating='post'
        )
        
        # Predict
        prediction = model.predict(padded, verbose=0)
        fake_prob = float(prediction[0][0])
        real_prob = 1.0 - fake_prob
        
        # Determine result
        result = "FAKE" if fake_prob > 0.5 else "REAL"
        confidence = fake_prob if fake_prob > 0.5 else real_prob
        
        return PredictionResponse(
            result=result,
            confidence=round(confidence, 4),
            model_version="kaggle-kfold-v1.0",
            fake_probability=round(fake_prob, 4),
            real_probability=round(real_prob, 4)
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Prediction failed: {str(e)}"
        )

# ============== Run Server ==============
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 7860))  # 7860 for HF Spaces, 8000 for local
    uvicorn.run(app, host="0.0.0.0", port=port)
