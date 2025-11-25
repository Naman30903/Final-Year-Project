# Fake News Detection - Final Year Project

> Full-stack application for detecting fake news using Deep Learning and Go backend

## 📁 Project Structure

```
Final_year_project/
├── backend/                    # Go Backend API
│   ├── cmd/                   # Application entry points
│   ├── internal/              # Private application code
│   │   ├── domain/           # Business logic & models
│   │   ├── handler/          # HTTP handlers
│   │   ├── repository/       # Data access layer
│   │   └── service/          # Business services
│   ├── pkg/                   # Public libraries
│   ├── bin/                   # Compiled binaries
│   └── kaggle_fake_news_detection.ipynb  # ML training notebook
│
└── frontend/                   # Frontend (To be implemented)
    └── (Coming soon)
```

## 🎯 Features

### Backend (Go)
- ✅ RESTful API for news analysis
- ✅ ML model integration via HTTP client
- ✅ URL scraping for article content extraction
- ✅ Prediction history storage
- ✅ Health check endpoints

### ML Model (Python/Kaggle)
- ✅ K-Fold Cross Validation (5 folds)
- ✅ Deep Learning: Embedding → Conv1D → BiLSTM → Attention
- ✅ L2 Regularization + Dropout
- ✅ Early Stopping & Model Checkpointing
- ✅ Counterfactual Generation
- ✅ Real-world article testing

## 🚀 Quick Start

### Backend Setup

```bash
cd backend

# Install dependencies
go mod download

# Build the application
go build -o bin/api cmd/api/main.go

# Set ML service URL (after deploying model)
export ML_SERVICE_URL=https://your-ml-service-url.com

# Run the server
./bin/api
```

The API will be available at `http://localhost:8080`

### ML Model Training (Kaggle)

1. Upload `backend/kaggle_fake_news_detection.ipynb` to Kaggle
2. Add ISOT Fake News Dataset
3. Enable GPU in Settings
4. Run all cells
5. Download trained model and tokenizer from Output panel

### ML Model Deployment

See `backend/` for deployment guides:
- Hugging Face Spaces (Recommended)
- Render
- Local deployment

## 📡 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/analyze` | Analyze news article (text or URL) |
| GET | `/api/predictions/:id` | Get prediction by ID |
| GET | `/api/history` | Get all prediction history |
| GET | `/api/health` | Health check |

### Example Request

```bash
# Analyze text
curl -X POST http://localhost:8080/api/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "type": "text",
    "content": "Your news article text here..."
  }'

# Analyze URL
curl -X POST http://localhost:8080/api/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "type": "url",
    "content": "https://example.com/news-article"
  }'
```

### Example Response

```json
{
  "id": "uuid",
  "result": "REAL",
  "confidence": 0.9234,
  "processing_time": "245ms",
  "model_version": "v1.0",
  "created_at": "2024-11-25T10:30:00Z"
}
```

## 🛠️ Tech Stack

### Backend
- **Language**: Go 1.21+
- **Architecture**: Clean Architecture (Domain-Driven Design)
- **HTTP Router**: Standard library (net/http)
- **Dependencies**: 
  - `github.com/google/uuid` - UUID generation

### ML Model
- **Framework**: TensorFlow 2.x / Keras
- **Training**: Kaggle (GPU enabled)
- **Dataset**: ISOT Fake News Dataset (~45K articles)
- **Deployment**: Hugging Face Spaces / Render
- **API Framework**: FastAPI + Uvicorn

### Frontend (Coming Soon)
- TBD

## 📊 Model Performance

- **Accuracy**: ~99% (K-Fold CV average)
- **Precision**: ~99%
- **Recall**: ~99%
- **F1-Score**: ~99%
- **Training Time**: ~45-70 minutes (with GPU)

## 🏗️ Architecture

### System Overview

```
┌─────────────┐      ┌──────────────┐      ┌─────────────────┐
│   Frontend  │ ───> │  Go Backend  │ ───> │   ML Service    │
│  (React?)   │      │   REST API   │      │ (FastAPI/Python)│
└─────────────┘      └──────────────┘      └─────────────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │  Repository  │
                     │  (In-Memory) │
                     └──────────────┘
```

### Backend Layers

1. **Handler Layer** (`internal/handler/`): HTTP request handling
2. **Service Layer** (`internal/service/`): Business logic
3. **Repository Layer** (`internal/repository/`): Data persistence
4. **Domain Layer** (`internal/domain/`): Core models and interfaces

## 📝 Development

### Prerequisites
- Go 1.21 or higher
- Python 3.9+ (for ML model)
- Git

### Backend Development

```bash
# Run tests
cd backend
go test ./...

# Run with hot reload (install air first)
air

# Format code
go fmt ./...

# Run linter
golangci-lint run
```

### Adding New Features

1. Define domain models in `internal/domain/`
2. Create repository interface and implementation
3. Implement business logic in `internal/service/`
4. Add HTTP handlers in `internal/handler/`
5. Register routes in `cmd/api/main.go`

## 🔐 Environment Variables

```bash
# Backend
ML_SERVICE_URL=https://your-ml-service.com  # ML model API endpoint
PORT=8080                                    # Server port (default: 8080)

# ML Service (when deploying)
PORT=7860                                    # For Hugging Face Spaces
PORT=8000                                    # For Render/local
```

## 📚 Documentation

- [Backend README](./backend/README.md)
- [Architecture Overview](./backend/ARCHITECTURE.md)
- [API Documentation](./backend/API_TESTING.md)
- [Kaggle Notebook Guide](./backend/KAGGLE_NOTEBOOK_GUIDE.md)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is for educational purposes as part of a Final Year Project.

## 👥 Team

- **Student**: Naman Jain
- **Institution**: [Your University]
- **Year**: 2024-2025

## 🙏 Acknowledgments

- ISOT Fake News Dataset creators
- TensorFlow and Keras communities
- Go programming community

## 📞 Contact

- GitHub: [@Naman30903](https://github.com/Naman30903)
- Repository: [Final-Year-Project](https://github.com/Naman30903/Final-Year-Project)

---

⭐ If you found this project helpful, please consider giving it a star!
