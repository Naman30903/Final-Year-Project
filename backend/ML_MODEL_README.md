# Enhanced Fake News Detection Model

Complete implementation with K-Fold Cross Validation, Regularization, Early Stopping, and Counterfactual Generator.

## Features

### ✅ Implemented

1. **K-Fold Cross Validation** (5-fold)
   - Robust performance evaluation
   - Mean accuracy with standard deviation
   - Per-fold model checkpoints

2. **L2 Regularization**
   - Applied to all trainable layers
   - Prevents overfitting
   - Configurable regularization strength

3. **Enhanced Early Stopping**
   - Monitors validation loss
   - Restores best weights
   - Patience of 3 epochs

4. **Learning Rate Reduction**
   - Reduces LR on plateau
   - Factor: 0.5
   - Patience: 2 epochs

5. **Counterfactual Generator**
   - Generates explanations for predictions
   - Modifies fake news to appear real
   - Identifies key indicator words
   - Interactive explanation system

## Model Architecture

```
Input (300 tokens)
    ↓
Embedding (64 dims) + L2 Regularization
    ↓
Conv1D (32 filters, kernel=5) + L2 Regularization
    ↓
MaxPooling1D (pool=2)
    ↓
Bidirectional LSTM (32 units) + L2 Regularization
    ↓
Attention Layer
    ↓
Bidirectional LSTM (16 units) + L2 Regularization
    ↓
Dropout (0.5)
    ↓
Dense (32 units, ReLU) + L2 Regularization
    ↓
Dense (1 unit, Sigmoid)
```

## Installation

```bash
pip install -r requirements_ml.txt
```

## Usage

### 1. Training the Model

```python
# Run the complete training pipeline
python enhanced_fake_news_model.py
```

This will:
- Load and preprocess the ISOT dataset
- Perform 5-fold cross validation
- Train the final model
- Generate visualizations
- Save all artifacts

### 2. Using the Trained Model

```python
import pickle
from tensorflow.keras.models import load_model

# Load model and tokenizer
model = load_model('fake_news_detector_final.h5')
with open('tokenizer.pkl', 'rb') as f:
    tokenizer = pickle.load(f)

# Make prediction
text = "Your news article here..."
# ... (preprocessing code)
prediction = model.predict(padded_text)
```

### 3. Generating Counterfactuals

```python
from enhanced_fake_news_model import CounterfactualGenerator

# Initialize generator
cf_gen = CounterfactualGenerator(model, tokenizer)

# Generate explanation
article = "Breaking news: shocking revelation!"
explanation = cf_gen.explain_prediction(article)
```

## Outputs

### Saved Files

1. **fake_news_detector_final.h5** - Final trained model
2. **tokenizer.pkl** - Fitted tokenizer
3. **model_config.pkl** - Model configuration
4. **best_model_fold_X.h5** - Best model for each fold (X = 1-5)
5. **training_metrics.png** - Training visualization
6. **kfold_results.png** - K-fold results visualization

### Performance Metrics

The model tracks:
- Accuracy
- Precision
- Recall
- F1-Score
- Confusion Matrix
- Per-fold performance

## Counterfactual Generator

### How It Works

The counterfactual generator:

1. **Identifies Fake Indicators**
   - Words: "shocking", "unbelievable", "exclusive", etc.
   - Phrases: "breaking", "bombshell", "share this"

2. **Generates Modifications**
   - Replaces sensational words with neutral alternatives
   - Removes emotional language
   - Adds/removes fake news patterns

3. **Validates Changes**
   - Re-predicts on modified text
   - Reports success rate
   - Shows modification impact

### Example Output

```
Original Text: "SHOCKING: Scientists confirm conspiracy!"
Original Prediction: FAKE (95.3%)

Modified Text: "Notable: Scientists report findings."
New Prediction: REAL (62.1%)

Modifications:
  - Replaced 'SHOCKING' with 'Notable'
  - Replaced 'confirm' with 'report'
  - Removed 'conspiracy'
```

## Configuration

Key parameters in the model:

```python
VOCAB_SIZE = 10000      # Vocabulary size
MAX_LENGTH = 300        # Maximum sequence length
EMBEDDING_DIM = 64      # Embedding dimension
N_FOLDS = 5            # Number of CV folds
EPOCHS = 10            # Training epochs
BATCH_SIZE = 64        # Batch size
L2_REG = 0.01          # L2 regularization strength
```

## Expected Performance

Based on the ISOT dataset:

- **Cross-Validation Accuracy**: ~98-99%
- **Test Accuracy**: ~98-99%
- **Precision**: ~0.98-0.99
- **Recall**: ~0.98-0.99
- **F1-Score**: ~0.98-0.99

## Advanced Features

### 1. Model Checkpointing

Models are saved after each fold:
- Best performing models preserved
- Can load specific fold models
- Ensemble predictions possible

### 2. Learning Rate Scheduling

Automatic LR reduction:
- Monitors validation loss
- Reduces by 50% on plateau
- Minimum LR: 1e-7

### 3. Comprehensive Callbacks

```python
callbacks = [
    EarlyStopping(...),
    ReduceLROnPlateau(...),
    ModelCheckpoint(...)
]
```

## Visualization

The script generates:

1. **Training Metrics Plot** (4 subplots)
   - Accuracy over epochs
   - Loss over epochs
   - Precision over epochs
   - Recall over epochs

2. **K-Fold Results Plot**
   - Bar chart of fold accuracies
   - Mean accuracy line
   - Visual comparison

## Integration with Backend

To use this model with your Go backend:

1. **Export to ONNX** (optional, for Go integration):
```python
import tf2onnx
spec = (tf.TensorSpec((None, 300), tf.int32, name="input"),)
output_path = model.save("model.onnx")
```

2. **Create FastAPI Service**:
```python
from fastapi import FastAPI
from enhanced_fake_news_model import CounterfactualGenerator

app = FastAPI()
model = load_model('fake_news_detector_final.h5')
cf_gen = CounterfactualGenerator(model, tokenizer)

@app.post("/predict")
def predict(text: str):
    pred = cf_gen.predict(text)
    return {
        "result": "FAKE" if pred > 0.5 else "REAL",
        "confidence": float(pred),
        "model_version": "v2.0-enhanced"
    }

@app.post("/explain")
def explain(text: str):
    explanation = cf_gen.explain_prediction(text)
    return explanation
```

3. **Deploy to Hugging Face Spaces** (see main README)

## Testing

Run tests with example articles:

```python
# Fake news example
fake_text = "BREAKING: Shocking revelation exposes conspiracy!"
pred = cf_gen.predict(fake_text)
# Expected: FAKE (high confidence)

# Real news example
real_text = "Central bank maintains current interest rates."
pred = cf_gen.predict(real_text)
# Expected: REAL (high confidence)
```

## Troubleshooting

### Out of Memory

Reduce batch size:
```python
BATCH_SIZE = 32  # or 16
```

### Overfitting

Increase regularization:
```python
L2_REG = 0.02  # or higher
```

Increase dropout:
```python
Dropout(0.6)  # instead of 0.5
```

### Underfitting

- Increase model capacity
- Reduce regularization
- Train for more epochs

## Citation

If you use this model in your research:

```
@article{fake_news_detection_2025,
  title={Enhanced Fake News Detection with Counterfactual Explanations},
  author={Your Name},
  year={2025}
}
```

## License

MIT License - see LICENSE file

## Contributing

Contributions welcome! Areas for improvement:

- [ ] Add more sophisticated counterfactual generation
- [ ] Implement LIME/SHAP explanations
- [ ] Add support for multiple languages
- [ ] Improve URL content extraction
- [ ] Add adversarial training
- [ ] Implement transfer learning

## Acknowledgments

- ISOT Fake News Dataset
- TensorFlow/Keras team
- Open source community
