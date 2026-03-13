# 🚀 Enhanced ML Model - Quick Start Guide

## What's New? 🎉

Your fake news detection model now includes:

✅ **K-Fold Cross Validation** (5-fold) - Robust performance evaluation  
✅ **L2 Regularization** - Prevents overfitting  
✅ **Enhanced Early Stopping** - Stops training at optimal point  
✅ **Learning Rate Reduction** - Adaptive learning  
✅ **Counterfactual Generator** - Explains predictions interactively  

---

## 📋 Prerequisites

```bash
# Install Python dependencies
pip install -r requirements_ml.txt
```

Required datasets (place in `/content/` or update paths):
- `Fake.csv` - Fake news articles
- `True.csv` - Real news articles

---

## 🎯 Training the Enhanced Model

### Option 1: Full Training Pipeline

```bash
# Run complete training with all features
python enhanced_fake_news_model.py
```

This will:
1. Load and preprocess ISOT dataset
2. Perform 5-fold cross validation
3. Train final model with regularization
4. Generate visualizations
5. Test counterfactual generator
6. Save all artifacts

**Expected Runtime**: 30-60 minutes (depending on hardware)

**Outputs**:
- `fake_news_detector_final.h5` - Final trained model
- `tokenizer.pkl` - Fitted tokenizer
- `model_config.pkl` - Model configuration
- `best_model_fold_1.h5` through `best_model_fold_5.h5` - Per-fold models
- `training_metrics.png` - Training visualizations
- `kfold_results.png` - Cross-validation results

---

## 🔮 Using the Trained Model

### Option 1: Python Script

```python
import pickle
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing.sequence import pad_sequences
import re

# Load model and tokenizer
model = load_model('fake_news_detector_final.h5')
with open('tokenizer.pkl', 'rb') as f:
    tokenizer = pickle.load(f)

# Clean and predict
def clean_text(text):
    text = str(text).lower()
    text = re.sub(r'[^a-zA-Z\s]', '', text)
    return ' '.join(text.split())

def predict_news(article):
    cleaned = clean_text(article)
    seq = tokenizer.texts_to_sequences([cleaned])
    padded = pad_sequences(seq, maxlen=300, padding='post')
    prob = model.predict(padded)[0][0]
    
    result = "FAKE" if prob > 0.5 else "REAL"
    confidence = prob if prob > 0.5 else (1 - prob)
    
    return result, confidence * 100

# Test it
article = "Breaking news: Shocking revelation exposes conspiracy!"
result, conf = predict_news(article)
print(f"Result: {result} ({conf:.1f}% confidence)")
```

### Option 2: FastAPI Service

```bash
# Start the API server
python ml_api_service.py
```

Server runs on `http://localhost:8000`

**Test with curl**:

```bash
# Basic prediction
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "Your news article here..."}'

# With counterfactual explanation
curl -X POST http://localhost:8000/explain \
  -H "Content-Type: application/json" \
  -d '{"text": "Your news article here...", "generate_counterfactual": true}'

# Health check
curl http://localhost:8000/health
```

**Response Example**:

```json
{
  "result": "FAKE",
  "confidence": 0.952,
  "model_version": "v2.0-enhanced",
  "fake_probability": 0.952,
  "real_probability": 0.048
}
```

---

## 🎭 Counterfactual Generator

### What It Does

The counterfactual generator:
1. Identifies "fake news indicators" in text
2. Modifies the text to flip the prediction
3. Shows what changes would make fake news appear real (and vice versa)

### Example Usage

```python
from enhanced_fake_news_model import CounterfactualGenerator

# Initialize
cf_gen = CounterfactualGenerator(model, tokenizer)

# Generate explanation
article = "SHOCKING: Scientists confirm conspiracy theory!"
explanation = cf_gen.explain_prediction(article)
```

**Output**:
```
Original Text: "SHOCKING: Scientists confirm conspiracy theory!"
Original Prediction: FAKE (95.3%)

Modified Text: "Notable: Scientists report findings."
New Prediction: REAL (62.1%)

Modifications:
  - Replaced 'SHOCKING' with 'Notable'
  - Replaced 'conspiracy theory' with 'findings'
```

### Fake News Indicators Detected

- Sensational words: "shocking", "unbelievable", "bombshell"
- Emotional appeals: "you won't believe", "amazing", "incredible"
- Urgency phrases: "share this", "before it's deleted"
- Conspiracy language: "hidden truth", "they don't want you to know"

---

## 📊 Model Performance

### Expected Results (ISOT Dataset)

| Metric | Score |
|--------|-------|
| Cross-Val Accuracy | 98-99% |
| Test Accuracy | 98-99% |
| Precision | 0.98-0.99 |
| Recall | 0.98-0.99 |
| F1-Score | 0.98-0.99 |

### Improvements Over Base Model

✅ **More Robust**: K-fold validation ensures consistent performance  
✅ **Less Overfitting**: L2 regularization + dropout  
✅ **Better Training**: Early stopping + LR reduction  
✅ **Explainable**: Counterfactual generation  

---

## 🔗 Integration with Go Backend

### Step 1: Update Backend ML Client

Your Go backend already has the ML client implemented. Update the expected response:

```go
// internal/service/ml_client.go

type MLPredictionResponse struct {
    Result          string  `json:"result"`
    Confidence      float64 `json:"confidence"`
    ModelVersion    string  `json:"model_version"`
    FakeProbability float64 `json:"fake_probability"`
    RealProbability float64 `json:"real_probability"`
}
```

### Step 2: Deploy ML Service

**Option A: Run Locally**
```bash
python ml_api_service.py
# Runs on http://localhost:8000
```

**Option B: Deploy to Hugging Face Spaces**
1. Create Space on huggingface.co
2. Upload files:
   - `ml_api_service.py` (rename to `app.py`)
   - `requirements_ml.txt` (rename to `requirements.txt`)
   - `fake_news_detector_final.h5`
   - `tokenizer.pkl`
   - `model_config.pkl`
3. Deploy and get URL

**Option C: Deploy to Render**
1. Push code to GitHub
2. Create Web Service on render.com
3. Set build command: `pip install -r requirements_ml.txt`
4. Set start command: `uvicorn ml_api_service:app --host 0.0.0.0 --port $PORT`

### Step 3: Configure Backend

```bash
cd backend
export ML_SERVICE_URL=http://localhost:8000  # or your deployment URL
./bin/api
```

### Step 4: Test End-to-End

```bash
# Test backend with ML service
curl -X POST http://localhost:8080/api/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "type": "text",
    "content": "Breaking: Shocking news that will amaze you!"
  }'
```

---

## 🛠️ Configuration

### Key Parameters

Edit these in `enhanced_fake_news_model.py`:

```python
VOCAB_SIZE = 10000      # Vocabulary size
MAX_LENGTH = 300        # Sequence length
EMBEDDING_DIM = 64      # Embedding dimension
N_FOLDS = 5             # CV folds
EPOCHS = 10             # Training epochs
BATCH_SIZE = 64         # Batch size
L2_REG = 0.01          # Regularization strength
```

### Tuning for Your Hardware

**Low Memory (< 8GB RAM)**:
```python
BATCH_SIZE = 32
VOCAB_SIZE = 5000
```

**High Memory (> 16GB RAM)**:
```python
BATCH_SIZE = 128
VOCAB_SIZE = 20000
```

---

## 📈 Visualizations

The training script generates:

### 1. Training Metrics (`training_metrics.png`)
- 4 subplots showing accuracy, loss, precision, recall
- Training vs validation curves
- Identifies overfitting/underfitting

### 2. K-Fold Results (`kfold_results.png`)
- Bar chart of per-fold accuracies
- Mean accuracy line
- Shows model consistency

---

## 🐛 Troubleshooting

### Issue: Out of Memory

**Solution**: Reduce batch size and vocabulary
```python
BATCH_SIZE = 16
VOCAB_SIZE = 5000
```

### Issue: Model Overfitting

**Solution**: Increase regularization
```python
L2_REG = 0.02  # Higher regularization
Dropout(0.6)   # More dropout
```

### Issue: Model Underfitting

**Solution**: Reduce regularization, train longer
```python
L2_REG = 0.005
EPOCHS = 15
```

### Issue: Slow Training

**Solution**: Use GPU acceleration
```python
# Check GPU availability
import tensorflow as tf
print("GPUs:", tf.config.list_physical_devices('GPU'))

# Enable mixed precision
from tensorflow.keras import mixed_precision
mixed_precision.set_global_policy('mixed_float16')
```

---

## 📝 File Structure

```
backend/
├── enhanced_fake_news_model.py      # Main training script
├── ml_api_service.py                # FastAPI service
├── requirements_ml.txt              # Python dependencies
├── ML_MODEL_README.md               # Detailed documentation
├── QUICKSTART_ML.md                 # This file
│
└── Generated Artifacts:
    ├── fake_news_detector_final.h5  # Final model
    ├── tokenizer.pkl                # Tokenizer
    ├── model_config.pkl             # Configuration
    ├── best_model_fold_*.h5         # Per-fold models
    ├── training_metrics.png         # Training plots
    └── kfold_results.png            # CV results
```

---

## 🎓 For Your Project Report

### Key Points to Highlight

1. **K-Fold Cross Validation**
   - Used 5-fold CV for robust evaluation
   - Mean accuracy: X% (±Y%)
   - Prevents overfitting to test set

2. **Regularization Techniques**
   - L2 regularization on all layers
   - Dropout (50%) for generalization
   - Prevents overfitting, improves real-world performance

3. **Advanced Training Callbacks**
   - Early stopping (patience=3)
   - Learning rate reduction on plateau
   - Model checkpointing

4. **Explainable AI**
   - Counterfactual generation
   - Identifies key indicators
   - Makes model decisions transparent

---

## 🚀 Next Steps

1. **Train the model**: Run `python enhanced_fake_news_model.py`
2. **Start API service**: Run `python ml_api_service.py`
3. **Test predictions**: Use curl or Postman
4. **Deploy to cloud**: Use Hugging Face Spaces or Render
5. **Connect to backend**: Update `ML_SERVICE_URL`
6. **Test end-to-end**: Analyze news through Go API

---

## 💡 Tips

- **Save training logs**: Redirect output to file for later analysis
- **Monitor GPU usage**: Use `nvidia-smi` during training
- **Experiment with hyperparameters**: Try different L2_REG values
- **Test on new data**: Collect recent news articles for testing
- **Document results**: Screenshot metrics for your report

---

## 🤝 Support

If you encounter issues:

1. Check Python version (3.8+ required)
2. Verify TensorFlow installation
3. Ensure datasets are in correct location
4. Review error messages carefully
5. Check ML_MODEL_README.md for details

---

**Your enhanced fake news detection model is ready! 🎉**

Good luck with your final year project! 🎓
