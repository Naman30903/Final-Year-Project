# Fake News Detection ML Service (RoBERTa)

FastAPI service for the new RoBERTa sequence-classification model.

## Important model notes from your notebook

- Label mapping in training is: `0 = FAKE`, `1 = REAL`.
- `tokenizer` must be initialized before encoding:

```python
tokenizer = AutoTokenizer.from_pretrained("roberta-base")
```

- You must save fine-tuned artifacts after training:

```python
save_dir = "./model"
model.save_pretrained(save_dir)
tokenizer.save_pretrained(save_dir)
```

These saved files (`config.json`, `model.safetensors` or `pytorch_model.bin`, tokenizer files) are what the API loads.

## Local development

1. Put your exported model directory at `ml-service/model/`.
2. Install and run:

```bash
pip install -r requirements.txt
uvicorn app:app --reload --port 8000
```

Optional environment variables:

- `MODEL_NAME_OR_PATH` (default: `./model`)
- `MODEL_VERSION` (default: `roberta-finetuned-v1`)
- `MAX_LENGTH` (default: `384`)

## Test API

```bash
curl http://localhost:8000/health
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"text":"Breaking: sample text"}'
```

## Deploy to Hugging Face Spaces (Docker)

1. Create a Space with Docker SDK.
2. Upload/push:
   - `app.py`
   - `requirements.txt`
   - `Dockerfile`
   - `model/` directory with exported artifacts
3. Wait for build.
4. Use URL: `https://<username>-<space>.hf.space`

## Connect to Go backend

Set:

```bash
export ML_SERVICE_URL="https://<username>-<space>.hf.space"
export ML_PREDICT_PATH="/predict"
export ML_HEALTH_PATH="/health"
```

If upstream is private:

```bash
export ML_SERVICE_API_KEY="<token>"
```
