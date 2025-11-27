# Fake News Detection ML Service

FastAPI service for the Kaggle-trained fake news detection model.

## Files Required

After running your Kaggle notebook, download and place these files here:

- `model_fold1.h5` - Trained Keras model
- `tokenizer.pkl` - Fitted tokenizer

## Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run the service
python app.py

# Or with uvicorn (hot reload)
uvicorn app:app --reload --port 8000
```

The API will be available at `http://localhost:8000`

## Test the API

```bash
# Health check
curl http://localhost:8000/health

# Predict
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "BREAKING: Scientists discover miracle cure!"}'
```

## Deploy to Hugging Face Spaces

1. Create a new Space at https://huggingface.co/spaces
2. Choose **Docker** as the SDK
3. Upload these files:
   - `Dockerfile`
   - `app.py`
   - `requirements.txt`
   - `model_fold1.h5` (from Kaggle)
   - `tokenizer.pkl` (from Kaggle)
4. Wait for build (~5-10 min)
5. Your API will be at: `https://YOUR-USERNAME-SPACE-NAME.hf.space`

## Connect to Go Backend

Set the ML service URL:

```bash
export ML_SERVICE_URL=https://YOUR-USERNAME-SPACE-NAME.hf.space
cd ../
./api
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | API info |
| `/health` | GET | Health check |
| `/predict` | POST | Analyze text |

### Predict Request

```json
{
  "text": "Your news article text here..."
}
```

### Predict Response

```json
{
  "result": "FAKE",
  "confidence": 0.9234,
  "model_version": "kaggle-kfold-v1.0",
  "fake_probability": 0.9234,
  "real_probability": 0.0766
}
```
