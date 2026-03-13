# Colab DL Model → VS Code → Hugging Face → Go Backend

## 1) Export artifacts from Colab

From your Colab notebook, save and download these files:

- `model_fold1.h5` (or your best model file)
- `tokenizer.pkl` (if your model expects tokenizer preprocessing)
- Optional: `model_config.pkl` (max length, labels, etc.)

> Keep preprocessing identical between training and inference.

## 2) Run locally in VS Code

Use the existing Python API service in `ml-service/`.

### Files expected in `ml-service/`

- `app.py`
- `requirements.txt`
- model artifacts (`.h5`, `.pkl`)

### Run

```bash
cd ml-service
pip install -r requirements.txt
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

### Test

```bash
curl http://localhost:8000/health
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"text":"Breaking: sample news text"}'
```

## 3) Deploy to Hugging Face Spaces

1. Create a new Space (Docker SDK recommended).
2. Push these files:
   - `app.py`
   - `requirements.txt`
   - model artifacts
   - `Dockerfile` (if using Docker Space)
3. Wait for build.
4. Note your base URL:
   - `https://<username>-<space-name>.hf.space`

## 4) Integrate with this Go backend

The backend now supports configurable API paths + bearer token.

Set env vars:

```bash
export ML_SERVICE_URL="https://<username>-<space-name>.hf.space"
export ML_PREDICT_PATH="/predict"
export ML_HEALTH_PATH="/health"
# Only if your upstream is protected:
export ML_SERVICE_API_KEY="<token>"
```

Run backend:

```bash
go run ./cmd/api
```

## 5) Remove old ML service safely

1. Switch backend to Hugging Face URL first.
2. Verify `/api/health` and `/api/analyze`.
3. Remove old service from deployment scripts/compose.
4. Keep rollback env value for `ML_SERVICE_URL` during first release.

## 6) Contract expected by backend

### Request to model API

`POST /predict`

```json
{ "text": "news text..." }
```

### Minimum response fields

```json
{
  "result": "FAKE",
  "confidence": 0.93,
  "model_version": "v1"
}
```

Additional fields are allowed.

## 7) Recommended next hardening

- Add request timeout + retries on HF cold starts.
- Add circuit breaker/fallback response in backend.
- Version your model via `model_version` and log it in predictions.
- Add one integration test against a mock `/predict` endpoint.
