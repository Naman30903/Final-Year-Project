# Final-Year-Project: Fake News Detection Backend

A production-ready Go backend for fake news detection, integrating ML models with clean architecture principles.

## 🎯 Overview

This backend service provides a RESTful API for analyzing news articles to detect fake news using machine learning. It supports both direct text analysis and URL scraping, with real-time predictions and analysis history.

## ✨ Features

- 📰 **Text Analysis**: Analyze news article text directly
- 🔗 **URL Scraping**: Extract and analyze content from URLs
- 🤖 **ML Integration**: Seamless integration with Python ML models
- 📊 **History Tracking**: Store and retrieve analysis history
- 🏥 **Health Monitoring**: ML service health checks
- ⚡ **Real-time Processing**: Immediate prediction results
- 🏗️ **Clean Architecture**: Maintainable and testable codebase

## 🚀 Quick Start

### Prerequisites
- Go 1.21+
- ML service running (see ML Model Setup)

### Build & Run

```bash
# Clone and navigate
cd backend

# Build (already done!)
./bin/api

# Or rebuild
go build -o bin/api ./cmd/api

# Set ML service URL and run
export ML_SERVICE_URL=http://localhost:8000
./bin/api
```

Server runs on: `http://localhost:8080`

### Quick Test

```bash
# Health check
curl http://localhost:8080/health

# Analyze text
curl -X POST http://localhost:8080/api/analyze \
  -H "Content-Type: application/json" \
  -d '{"type":"text","content":"Your news article here..."}'
```

## 📁 Project Structure

```
.
├── cmd/                    # Main applications
│   └── api/               # API server entry point
│       └── main.go
├── internal/              # Private application code
│   ├── domain/           # Domain entities/models
│   │   ├── news.go       # News article models
│   │   ├── prediction.go # Prediction models
│   │   ├── user.go       # User models
│   │   └── errors.go     # Custom errors
│   ├── repository/       # Data access layer
│   │   └── memory/       # In-memory implementation
│   │       ├── user_repository.go
│   │       └── prediction_repository.go
│   ├── service/          # Business logic layer
│   │   ├── user_service.go
│   │   ├── news_service.go      # News analysis logic
│   │   ├── ml_client.go         # ML service client
│   │   └── scraper_service.go   # URL scraping
│   └── handler/          # HTTP handlers
│       ├── user_handler.go
│       └── news_handler.go      # News API handlers
├── pkg/                   # Public libraries
│   └── logger/           # Logging utilities
├── scripts/              # Build and deployment scripts
│   └── fix_and_build.sh
├── example_ml_service.py # Example ML service
├── example_requirements.txt
├── SETUP_COMPLETE.md     # Complete setup guide
├── INTEGRATION_GUIDE.md  # Detailed API documentation
├── API_TESTING.md        # Testing examples
├── ARCHITECTURE_OVERVIEW.md # System architecture
├── QUICK_REFERENCE.md    # Quick reference card
├── Makefile              # Build commands
├── Dockerfile            # Docker configuration
├── go.mod                # Go module file
└── README.md
```

## 📡 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/analyze` | Analyze news (text or URL) |
| GET | `/api/predictions?id={id}` | Get specific prediction |
| GET | `/api/history` | Get all analysis history |
| GET | `/api/health` | Check ML service status |
| GET | `/health` | Basic health check |

### Example Requests

**Analyze Text:**
```bash
curl -X POST http://localhost:8080/api/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "type": "text",
    "content": "Breaking news article text..."
  }'
```

**Analyze URL:**
```bash
curl -X POST http://localhost:8080/api/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "type": "url",
    "content": "https://example.com/news-article"
  }'
```

**Get History:**
```bash
curl http://localhost:8080/api/history
```

## 🤖 ML Model Setup

### Recommended: Hugging Face Spaces (FREE)

1. **Create Space**: https://huggingface.co/spaces
2. **Choose FastAPI** template
3. **Upload files**:
   - Copy `example_ml_service.py` as `app.py`
   - Copy `example_requirements.txt` as `requirements.txt`
4. **Deploy** → Get URL (e.g., `https://username-space.hf.space`)
5. **Configure Backend**:
   ```bash
   export ML_SERVICE_URL=https://username-space.hf.space
   ```

### Alternative Options:
- **Render**: Free tier with cold starts
- **Google Cloud Run**: Generous free tier
- **Local**: Run Python service on port 8000

See `INTEGRATION_GUIDE.md` for detailed setup instructions.

## 🏗️ Architecture

This project follows **Clean Architecture** principles:

```
Client → Handler → Service → Repository
                      ↓
                 ML Service
```

### Layers:
- **Domain Layer**: Core business entities and rules
- **Handler Layer**: HTTP request/response handling
- **Service Layer**: Business logic orchestration
- **Repository Layer**: Data access abstraction

See `ARCHITECTURE_OVERVIEW.md` for detailed architecture documentation.

## ✨ Best Practices Implemented

### Architecture & Design
- ✅ Clean Architecture with clear boundaries
- ✅ Dependency Injection for loose coupling
- ✅ Interface-based design for testability
- ✅ Repository pattern for data access abstraction
- ✅ Domain-Driven Design principles

### Code Quality
- ✅ Proper error handling with context
- ✅ Context propagation throughout the stack
- ✅ Graceful shutdown with signal handling
- ✅ Concurrency-safe implementations (mutex locks)
- ✅ Structured logging
- ✅ Configuration management

### Development
- ✅ Makefile for common tasks
- ✅ Docker support for containerization
- ✅ Go modules for dependency management
````markdown
# Go Backend Project

A production-ready Go backend following clean architecture principles and best practices.

## 📁 Project Structure

```
.
├── cmd/                    # Main applications
│   └── api/               # API server entry point
│       └── main.go
├── internal/              # Private application code
│   ├── domain/           # Domain entities/models
│   │   └── user.go
│   ├── repository/       # Data access layer
│   │   ├── user_repository.go
│   │   └── memory/       # In-memory implementation
│   │       └── user_repository.go
│   ├── service/          # Business logic layer
│   │   └── user_service.go
│   └── handler/          # HTTP handlers
│       └── user_handler.go
├── pkg/                   # Public libraries
│   └── logger/           # Logging utilities
│       └── logger.go
├── config/               # Configuration files
├── migrations/           # Database migrations
├── scripts/              # Build and deployment scripts
├── tests/                # Integration tests
├── Makefile              # Build commands
├── Dockerfile            # Docker configuration
├── go.mod                # Go module file
└── README.md
```

## 🏗️ Architecture

This project follows **Clean Architecture** principles with clear separation of concerns:

- **Domain Layer**: Core business entities and rules
- **Repository Layer**: Data access abstraction
- **Service Layer**: Business logic orchestration
- **Handler Layer**: HTTP request/response handling

## ✨ Best Practices Implemented

### Architecture & Design
- ✅ Clean Architecture with clear boundaries
- ✅ Dependency Injection for loose coupling
- ✅ Interface-based design for testability
- ✅ Repository pattern for data access abstraction
- ✅ Domain-Driven Design principles

### Code Quality
- ✅ Proper error handling with context
- ✅ Context propagation throughout the stack
- ✅ Graceful shutdown with signal handling
- ✅ Concurrency-safe implementations (mutex locks)
- ✅ Structured logging
- ✅ Configuration management

### Development
- ✅ Makefile for common tasks
- ✅ Docker support for containerization
- ✅ Go modules for dependency management
- ✅ Clear project structure following Go standards

## 🚀 Getting Started

### Prerequisites

- Go 1.21 or higher
- Make (optional but recommended)
- Docker (optional, for containerization)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd backend
```

2. Install dependencies:
```bash
make deps
```

### Running the Application

#### Using Make:
```bash
make run
```

#### Using Go directly:
```bash
go run cmd/api/main.go
```

#### Using Docker:
```bash
docker build -t go-backend .
docker run -p 8080:8080 go-backend
```

The server will start on `http://localhost:8080`

### Available Endpoints

- `GET /health` - Health check endpoint

## 🧪 Testing

Run all tests:
```bash
make test
```

Run tests with coverage:
```bash
make test
make coverage
```

## 🛠️ Development

### Build Commands

- `make build` - Build the application
- `make run` - Run the application
- `make test` - Run tests
- `make coverage` - Generate coverage report
- `make clean` - Clean build artifacts
- `make lint` - Run linter (requires golangci-lint)
- `make deps` - Download and tidy dependencies
- `make help` - Show all available commands

### Code Structure Guidelines

#### Adding a New Entity

1. Create domain model in `internal/domain/`
2. Define repository interface in `internal/repository/`
3. Implement repository in `internal/repository/memory/` (or other storage)
4. Create service in `internal/service/`
5. Add HTTP handlers in `internal/handler/`
6. Wire everything in `cmd/api/main.go`

#### Example: Adding a Product Entity

```go
// 1. Domain (internal/domain/product.go)
type Product struct {
    ID    string
    Name  string
    Price float64
}

// 2. Repository Interface (internal/repository/product_repository.go)
type ProductRepository interface {
    Create(ctx context.Context, product *domain.Product) error
    // ... other methods
}

// 3. Implementation (internal/repository/memory/product_repository.go)
type ProductRepository struct {
    // implementation
}

// 4. Service (internal/service/product_service.go)
type ProductService struct {
    repo repository.ProductRepository
}

// 5. Handler (internal/handler/product_handler.go)
type ProductHandler struct {
    service *service.ProductService
}
```

## 📝 Configuration

Environment variables:
- `PORT` - Server port (default: 8080)
- `LOG_LEVEL` - Logging level (default: info)

## 🔒 Security Best Practices

- Context-based request cancellation
- Proper timeout configurations
- Input validation in domain layer
- Thread-safe concurrent operations

## 🐳 Docker

Build and run with Docker:
```bash
docker build -t go-backend .
docker run -p 8080:8080 go-backend
```

## 📚 Additional Resources

- [Effective Go](https://golang.org/doc/effective_go.html)
- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- [Standard Go Project Layout](https://github.com/golang-standards/project-layout)

## 🤝 Contributing

1. Follow the existing code structure
2. Write tests for new features
3. Ensure all tests pass before submitting
4. Follow Go conventions and best practices

## 📄 License

This project is licensed under the MIT License.

````
