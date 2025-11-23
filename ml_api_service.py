# -*- coding: utf-8 -*-
"""
FastAPI Service for Enhanced Fake News Detection Model
Includes counterfactual explanations
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
from typing import Optional, List
import uvicorn

# ============================================================================
# CONFIGURATION
# ============================================================================

app = FastAPI(
    title="Enhanced Fake News Detection API",
    description="Detect fake news with counterfactual explanations",
    version="2.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global variables
model = None
tokenizer = None
config = None
MAX_LENGTH = 300

# ============================================================================
# DATA MODELS
# ============================================================================

class PredictionRequest(BaseModel):
    text: str

class PredictionResponse(BaseModel):
    result: str
    confidence: float
    model_version: str
    fake_probability: float
    real_probability: float

class ExplanationRequest(BaseModel):
    text: str
    generate_counterfactual: bool = True

class Modification(BaseModel):
    type: str
    original: str
    replacement: str
    description: str

class CounterfactualResponse(BaseModel):
    original_text: str
    modified_text: Optional[str]
    original_prediction: str
    original_confidence: float
    new_prediction: Optional[str]
    new_confidence: Optional[float]
    modifications: List[str]
    success: bool
    key_indicators: List[str]

class ExplanationResponse(BaseModel):
    prediction: PredictionResponse
    counterfactual: Optional[CounterfactualResponse]
    explanation: str


# ============================================================================
# COUNTERFACTUAL GENERATOR
# ============================================================================

class CounterfactualGenerator:
    """Generate counterfactual explanations"""
    
    def __init__(self, model, tokenizer, max_length=300):
        self.model = model
        self.tokenizer = tokenizer
        self.max_length = max_length
        
        self.fake_indicators = [
            'shocking', 'unbelievable', 'bombshell', 'exclusive', 'breaking',
            'revealed', 'exposed', 'conspiracy', 'hidden', 'secret',
            'truth', 'mainstream media', 'click here', 'share this',
            'wow', 'incredible', 'amazing', 'must see', 'urgent'
        ]
        
        self.neutral_replacements = {
            'shocking': 'notable',
            'unbelievable': 'significant',
            'bombshell': 'report',
            'exclusive': 'news',
            'breaking': 'recent',
            'revealed': 'reported',
            'exposed': 'disclosed',
            'conspiracy': 'theory',
            'hidden': 'undisclosed',
            'secret': 'private',
            'incredible': 'noteworthy',
            'amazing': 'interesting',
            'wow': '',
            'must see': '',
            'urgent': 'timely'
        }
    
    def clean_text(self, text):
        """Clean and normalize text"""
        text = str(text).lower()
        text = re.sub(r'\(reuters\)|(washington|london|moscow|etc) -', '', text)
        text = re.sub(r'[^a-zA-Z\s]', '', text)
        text = ' '.join(text.split())
        return text
    
    def predict(self, text):
        """Make prediction on text"""
        cleaned = self.clean_text(text)
        seq = self.tokenizer.texts_to_sequences([cleaned])
        padded = pad_sequences(seq, maxlen=self.max_length,
                              padding='post', truncating='post')
        prob = self.model.predict(padded, verbose=0)[0][0]
        return float(prob)
    
    def identify_indicators(self, text):
        """Identify fake news indicators in text"""
        text_lower = text.lower()
        found_indicators = []
        for indicator in self.fake_indicators:
            if indicator in text_lower:
                found_indicators.append(indicator)
        return found_indicators
    
    def generate_counterfactual(self, original_text, target_class='flip'):
        """Generate counterfactual explanation"""
        original_pred = self.predict(original_text)
        original_class = 'FAKE' if original_pred > 0.5 else 'REAL'
        
        # Determine target
        if target_class == 'flip':
            target = 0.0 if original_pred > 0.5 else 1.0
        elif target_class == 'real':
            target = 0.0
        elif target_class == 'fake':
            target = 1.0
        else:
            target = 0.0 if original_pred > 0.5 else 1.0
        
        modified_text = original_text
        modifications = []
        
        # Strategy: Remove/Replace fake indicators to make it real
        if target == 0.0:
            words = modified_text.split()
            for i, word in enumerate(words):
                word_clean = re.sub(r'[^a-zA-Z]', '', word.lower())
                if word_clean in self.fake_indicators:
                    replacement = self.neutral_replacements.get(word_clean, '')
                    if replacement:
                        words[i] = replacement
                        modifications.append(
                            f"Replaced '{word}' with '{replacement}'"
                        )
                    elif not replacement and word_clean in ['wow', 'must see']:
                        words[i] = ''
                        modifications.append(f"Removed '{word}'")
            modified_text = ' '.join([w for w in words if w])
        
        # Strategy: Add fake indicators to make it fake
        elif target == 1.0:
            fake_prefixes = [
                'BREAKING: ',
                'SHOCKING: ',
                'EXCLUSIVE: ',
                'UNBELIEVABLE: '
            ]
            prefix = np.random.choice(fake_prefixes)
            modified_text = prefix + modified_text
            modifications.append(f"Added sensational prefix: '{prefix.strip()}'")
        
        # Check new prediction
        new_pred = self.predict(modified_text)
        new_class = 'FAKE' if new_pred > 0.5 else 'REAL'
        
        # Identify key indicators
        indicators = self.identify_indicators(original_text)
        
        return {
            'original_text': original_text,
            'modified_text': modified_text,
            'original_prediction': original_class,
            'original_confidence': float(original_pred),
            'new_prediction': new_class,
            'new_confidence': float(new_pred),
            'modifications': modifications,
            'success': (new_pred > 0.5) == (target > 0.5),
            'key_indicators': indicators
        }


# ============================================================================
# STARTUP/SHUTDOWN
# ============================================================================

@app.on_event("startup")
async def load_model_artifacts():
    """Load model, tokenizer, and config on startup"""
    global model, tokenizer, config, MAX_LENGTH
    
    try:
        print("Loading model artifacts...")
        
        # Load model
        model = load_model('fake_news_detector_final.h5')
        print("✓ Model loaded")
        
        # Load tokenizer
        with open('tokenizer.pkl', 'rb') as f:
            tokenizer = pickle.load(f)
        print("✓ Tokenizer loaded")
        
        # Load config
        try:
            with open('model_config.pkl', 'rb') as f:
                config = pickle.load(f)
            MAX_LENGTH = config.get('max_length', 300)
            print("✓ Config loaded")
        except:
            config = {'max_length': 300}
            MAX_LENGTH = 300
            print("⚠ Config not found, using defaults")
        
        print("✓ All artifacts loaded successfully!")
        
    except Exception as e:
        print(f"❌ Error loading model artifacts: {e}")
        raise


# ============================================================================
# API ENDPOINTS
# ============================================================================

@app.get("/")
def root():
    """Root endpoint with API information"""
    return {
        "name": "Enhanced Fake News Detection API",
        "version": "2.0.0",
        "description": "Detect fake news with counterfactual explanations",
        "endpoints": {
            "/predict": "POST - Get fake news prediction",
            "/explain": "POST - Get prediction with counterfactual explanation",
            "/health": "GET - Health check",
            "/info": "GET - Model information"
        }
    }


@app.get("/health")
def health_check():
    """Health check endpoint"""
    if model is None or tokenizer is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    return {
        "status": "healthy",
        "model_loaded": model is not None,
        "tokenizer_loaded": tokenizer is not None,
        "model_version": "v2.0-enhanced"
    }


@app.get("/info")
def model_info():
    """Get model information"""
    if config is None:
        return {
            "model_version": "v2.0-enhanced",
            "features": [
                "K-Fold Cross Validation",
                "L2 Regularization",
                "Early Stopping",
                "Counterfactual Generation"
            ]
        }
    
    return {
        "model_version": "v2.0-enhanced",
        "configuration": config,
        "features": [
            "K-Fold Cross Validation",
            "L2 Regularization",
            "Early Stopping",
            "Learning Rate Reduction",
            "Counterfactual Generation"
        ]
    }


@app.post("/predict", response_model=PredictionResponse)
def predict(request: PredictionRequest):
    """
    Predict if news article is fake or real
    
    Args:
        request: PredictionRequest with text field
    
    Returns:
        PredictionResponse with result, confidence, and probabilities
    """
    try:
        if not request.text or len(request.text.strip()) == 0:
            raise HTTPException(status_code=400, detail="Text cannot be empty")
        
        # Clean text
        def clean_text(text):
            text = str(text).lower()
            text = re.sub(r'\(reuters\)|(washington|london|moscow|etc) -', '', text)
            text = re.sub(r'[^a-zA-Z\s]', '', text)
            text = ' '.join(text.split())
            return text
        
        cleaned = clean_text(request.text)
        
        # Tokenize and pad
        sequences = tokenizer.texts_to_sequences([cleaned])
        padded = pad_sequences(sequences, maxlen=MAX_LENGTH,
                              padding='post', truncating='post')
        
        # Predict
        prediction = model.predict(padded, verbose=0)
        fake_prob = float(prediction[0][0])
        real_prob = 1.0 - fake_prob
        
        result = "FAKE" if fake_prob > 0.5 else "REAL"
        confidence = fake_prob if fake_prob > 0.5 else real_prob
        
        return PredictionResponse(
            result=result,
            confidence=confidence,
            model_version="v2.0-enhanced",
            fake_probability=fake_prob,
            real_probability=real_prob
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")


@app.post("/explain", response_model=ExplanationResponse)
def explain(request: ExplanationRequest):
    """
    Get prediction with counterfactual explanation
    
    Args:
        request: ExplanationRequest with text and counterfactual flag
    
    Returns:
        ExplanationResponse with prediction and counterfactual
    """
    try:
        if not request.text or len(request.text.strip()) == 0:
            raise HTTPException(status_code=400, detail="Text cannot be empty")
        
        # Get prediction
        pred_request = PredictionRequest(text=request.text)
        prediction = predict(pred_request)
        
        # Generate counterfactual if requested
        counterfactual_data = None
        explanation_text = ""
        
        if request.generate_counterfactual:
            cf_gen = CounterfactualGenerator(model, tokenizer, MAX_LENGTH)
            cf_result = cf_gen.generate_counterfactual(request.text)
            
            counterfactual_data = CounterfactualResponse(**cf_result)
            
            # Generate explanation
            if cf_result['key_indicators']:
                explanation_text = (
                    f"The article was classified as {prediction.result} "
                    f"with {prediction.confidence * 100:.1f}% confidence. "
                    f"Key indicators found: {', '.join(cf_result['key_indicators'][:3])}. "
                )
            else:
                explanation_text = (
                    f"The article was classified as {prediction.result} "
                    f"with {prediction.confidence * 100:.1f}% confidence. "
                )
            
            if cf_result['modifications']:
                explanation_text += (
                    f"To flip the prediction, we could: "
                    f"{'; '.join(cf_result['modifications'][:2])}."
                )
        else:
            explanation_text = (
                f"The article was classified as {prediction.result} "
                f"with {prediction.confidence * 100:.1f}% confidence."
            )
        
        return ExplanationResponse(
            prediction=prediction,
            counterfactual=counterfactual_data,
            explanation=explanation_text
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Explanation generation failed: {str(e)}"
        )


# ============================================================================
# RUN SERVER
# ============================================================================

if __name__ == "__main__":
    print("=" * 70)
    print("Enhanced Fake News Detection API Server")
    print("=" * 70)
    print("\nStarting server on http://0.0.0.0:8000")
    print("\nEndpoints:")
    print("  - POST /predict - Get prediction")
    print("  - POST /explain - Get prediction with explanation")
    print("  - GET /health - Health check")
    print("  - GET /info - Model information")
    print("\nPress CTRL+C to stop")
    print("=" * 70)
    
    uvicorn.run(app, host="0.0.0.0", port=8000)
