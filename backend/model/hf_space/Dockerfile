FROM python:3.11-slim

WORKDIR /app

# Install system deps for lxml
RUN apt-get update && apt-get install -y --no-install-recommends \
    libxml2-dev libxslt1-dev gcc \
    && rm -rf /var/lib/apt/lists/*

COPY ../requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy inference code
COPY ../newmodel.py .
COPY ./app.py .

# Optional: copy a pre-downloaded model into the image.
# If MODEL_NAME_OR_PATH points to a HF repo the model is downloaded at startup.
# COPY ./model ./model

ENV MODEL_NAME_OR_PATH=./model
ENV PORT=7860

EXPOSE 7860

CMD ["uvicorn", "newmodel:app", "--host", "0.0.0.0", "--port", "7860"]
