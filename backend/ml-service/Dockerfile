FROM python:3.10-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy model files and app
COPY model_fold1.h5 .
COPY tokenizer.pkl .
COPY app.py .

# Expose port (7860 for Hugging Face Spaces)
EXPOSE 7860

# Run the app
CMD ["python", "app.py"]
