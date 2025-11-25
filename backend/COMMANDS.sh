#!/bin/bash
# Quick Commands Reference for Fake News Detection System

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Fake News Detection System - Quick Commands             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  $1"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
}

# SETUP COMMANDS
print_section "SETUP COMMANDS"
cat << 'EOF'
# Install Python dependencies
pip install -r requirements_ml.txt

# Install Go dependencies
go mod tidy

# Build Go backend
go build -o bin/api ./cmd/api
EOF

# TRAINING
print_section "TRAINING ML MODEL"
cat << 'EOF'
# Train the enhanced model (takes 30-60 minutes)
python enhanced_fake_news_model.py

# Expected outputs:
#   - fake_news_detector_final.h5
#   - tokenizer.pkl
#   - model_config.pkl
#   - best_model_fold_*.h5 (5 files)
#   - training_metrics.png
#   - kfold_results.png
EOF

# RUNNING SERVICES
print_section "RUNNING SERVICES"
cat << 'EOF'
# Start ML Service (Port 8000)
python ml_api_service.py

# Start Go Backend (Port 8080) - in another terminal
export ML_SERVICE_URL=http://localhost:8000
./bin/api
EOF

# TESTING
print_section "TESTING COMMANDS"
cat << 'EOF'
# Test ML Service Health
curl http://localhost:8000/health

# Test ML Prediction
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "SHOCKING: Unbelievable news!"}'

# Test ML with Counterfactual Explanation
curl -X POST http://localhost:8000/explain \
  -H "Content-Type: application/json" \
  -d '{"text": "SHOCKING: Unbelievable news!", "generate_counterfactual": true}'

# Test Go Backend Health
curl http://localhost:8080/health

# Test Go Backend Text Analysis
curl -X POST http://localhost:8080/api/analyze \
  -H "Content-Type: application/json" \
  -d '{"type": "text", "content": "Breaking news article..."}'

# Test Go Backend URL Analysis
curl -X POST http://localhost:8080/api/analyze \
  -H "Content-Type: application/json" \
  -d '{"type": "url", "content": "https://example.com/article"}'

# Get Analysis History
curl http://localhost:8080/api/history
EOF

# DEPLOYMENT
print_section "DEPLOYMENT TO HUGGING FACE SPACES"
cat << 'EOF'
# 1. Train model locally first
python enhanced_fake_news_model.py

# 2. Create Space on huggingface.co
#    - Choose "FastAPI" template

# 3. Rename files for deployment
cp ml_api_service.py app.py
cp requirements_ml.txt requirements.txt

# 4. Upload to Space:
#    - app.py
#    - requirements.txt
#    - fake_news_detector_final.h5
#    - tokenizer.pkl
#    - model_config.pkl

# 5. Get your Space URL (e.g., https://username-space.hf.space)

# 6. Update Go backend
export ML_SERVICE_URL=https://username-space.hf.space
./bin/api
EOF

# GIT COMMANDS
print_section "GIT COMMANDS"
cat << 'EOF'
# Check what's being tracked
git status

# View ignored files (they won't show in status)
git status --ignored

# Commit your changes
git add .
git commit -m "Add enhanced ML model with K-fold CV and counterfactuals"
git push origin main
EOF

# TROUBLESHOOTING
print_section "TROUBLESHOOTING"
cat << 'EOF'
# Check if ML service is running
lsof -i :8000

# Check if Go backend is running
lsof -i :8080

# Kill process on port 8000
kill -9 $(lsof -ti:8000)

# Kill process on port 8080
kill -9 $(lsof -ti:8080)

# Check Python version (needs 3.8+)
python --version

# Check Go version (needs 1.21+)
go version

# Check GPU availability
python -c "import tensorflow as tf; print('GPUs:', tf.config.list_physical_devices('GPU'))"

# View logs while running
python ml_api_service.py 2>&1 | tee ml_service.log
./bin/api 2>&1 | tee backend.log
EOF

# FILE LOCATIONS
print_section "IMPORTANT FILE LOCATIONS"
cat << 'EOF'
Source Code:
  - enhanced_fake_news_model.py     # ML training script
  - ml_api_service.py               # FastAPI service
  - cmd/api/main.go                 # Go backend main
  - internal/service/ml_client.go   # ML client in Go

Documentation:
  - COMPLETE_SUMMARY.md             # This summary
  - QUICKSTART_ML.md                # ML quick start
  - ML_MODEL_README.md              # Detailed ML docs
  - SETUP_COMPLETE.md               # Complete setup guide

Generated Artifacts (ignored by git):
  - fake_news_detector_final.h5     # Trained model
  - tokenizer.pkl                   # Tokenizer
  - model_config.pkl                # Configuration
  - training_metrics.png            # Training plots
  - kfold_results.png               # CV results
EOF

# QUICK TESTING
print_section "QUICK END-TO-END TEST"
cat << 'EOF'
# Terminal 1: Start ML service
python ml_api_service.py

# Terminal 2: Start Go backend
export ML_SERVICE_URL=http://localhost:8000
./bin/api

# Terminal 3: Test everything
curl -X POST http://localhost:8080/api/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "type": "text",
    "content": "SHOCKING: Scientists discover amazing breakthrough that will change everything! Click here to see what mainstream media does not want you to know!"
  }' | jq

# Expected: Classification as FAKE with high confidence
EOF

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   For detailed documentation, see:                         ║"
echo "║   - COMPLETE_SUMMARY.md                                    ║"
echo "║   - QUICKSTART_ML.md                                       ║"
echo "║   - ML_MODEL_README.md                                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
