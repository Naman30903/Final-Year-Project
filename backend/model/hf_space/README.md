---
title: Fake News Detection API
emoji: 🔍
colorFrom: blue
colorTo: red
sdk: docker
pinned: false
license: mit
---

# Fake News Detection API

RoBERTa fine-tuned on the WELFake dataset for binary fake / real news classification.

## Endpoints

| Method | Path | Body | Description |
|--------|------|------|-------------|
| GET | `/` | — | API info |
| GET | `/health` | — | Readiness check |
| POST | `/predict` | `{"text": "..."}` | Classify raw text |
| POST | `/predict/url` | `{"url": "https://..."}` | Scrape article & classify |

## Example

```bash
# plain text
curl -X POST https://YOUR_SPACE.hf.space/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "Scientists discover water on Mars surface."}'

# article URL
curl -X POST https://YOUR_SPACE.hf.space/predict/url \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.bbc.com/news/some-article"}'
```

## Environment variables (Space secrets)

| Variable | Default | Description |
|----------|---------|-------------|
| `MODEL_NAME_OR_PATH` | `./model` | HF repo ID or local path |
| `MODEL_VERSION` | `roberta-finetuned-v1` | Label returned in responses |
| `MAX_LENGTH` | `384` | Tokeniser truncation length |
| `FAKE_LABEL_ID` | `0` | Class index for FAKE |
| `REAL_LABEL_ID` | `1` | Class index for REAL |
| `SCRAPE_TIMEOUT` | `15` | Seconds before URL fetch times out |

## Training

See `train_kaggle.py` for the full Kaggle training script.
