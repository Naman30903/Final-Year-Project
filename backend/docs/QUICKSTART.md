# Quick Start Guide

## Setup Instructions

### 1. Initial Setup
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run setup script
./scripts/setup.sh
```

### 2. Configuration
Copy `.env.example` to `.env` and update with your values:
```bash
cp .env.example .env
```

### 3. Build and Run

#### Option A: Using Make
```bash
# Build the application
make build

# Run the application
make run

# Run tests
make test

# Generate coverage report
make coverage
```

#### Option B: Using Go directly
```bash
# Run directly
go run cmd/api/main.go

# Build first, then run
go build -o bin/api cmd/api/main.go
./bin/api
```

#### Option C: Using Docker
```bash
# Build Docker image
docker build -t go-backend .

# Run container
docker run -p 8080:8080 go-backend
```

#### Option D: Using Docker Compose
```bash
# Start all services (app + database)
docker-compose up

# Run in background
docker-compose up -d

# Stop services
docker-compose down
```

## Testing the API

Once the server is running, test it:

```bash
# Health check endpoint
curl http://localhost:8080/health
```

Expected response: `OK`

## Development Workflow

### Running Tests
```bash
# Run all tests
go test ./...

# Run tests with coverage
go test -cover ./...

# Run tests with verbose output
go test -v ./...

# Run specific test
go test -v ./internal/domain
```

### Code Quality

```bash
# Format code
go fmt ./...

# Vet code
go vet ./...

# Run linter (requires golangci-lint)
make lint

# Or install and run golangci-lint
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
golangci-lint run
```

### Adding Dependencies

```bash
# Add a new dependency
go get github.com/some/package

# Update dependencies
go mod tidy
```

## Project Structure Overview

```
backend/
├── cmd/api/              # Application entry point
├── internal/             # Private application code
│   ├── domain/          # Business entities
│   ├── repository/      # Data access
│   ├── service/         # Business logic
│   └── handler/         # HTTP handlers
├── pkg/                 # Public libraries
├── config/              # Configuration
├── scripts/             # Build/deploy scripts
└── tests/               # Integration tests
```

## Common Commands

| Command | Description |
|---------|-------------|
| `make build` | Build the application |
| `make run` | Run the application |
| `make test` | Run all tests |
| `make coverage` | Generate coverage report |
| `make clean` | Clean build artifacts |
| `make deps` | Download dependencies |
| `make lint` | Run linter |
| `make help` | Show all commands |

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | 8080 |
| `READ_TIMEOUT` | Read timeout (seconds) | 15 |
| `WRITE_TIMEOUT` | Write timeout (seconds) | 15 |
| `IDLE_TIMEOUT` | Idle timeout (seconds) | 60 |
| `DB_HOST` | Database host | localhost |
| `DB_PORT` | Database port | 5432 |
| `DB_USER` | Database user | postgres |
| `DB_PASSWORD` | Database password | - |
| `DB_NAME` | Database name | myapp |
| `LOG_LEVEL` | Log level | info |

## Troubleshooting

### Port already in use
```bash
# Find process using port 8080
lsof -i :8080

# Kill the process
kill -9 <PID>
```

### Module import issues
```bash
# Clean module cache
go clean -modcache

# Re-download dependencies
go mod download
go mod tidy
```

### Build issues
```bash
# Clean build artifacts
make clean

# Rebuild
make build
```

## Next Steps

1. **Add a database**: Implement PostgreSQL or MySQL repository
2. **Add middleware**: Authentication, logging, CORS
3. **Add API documentation**: Swagger/OpenAPI
4. **Add more endpoints**: Create full CRUD operations
5. **Add validation**: Request validation middleware
6. **Add rate limiting**: Protect against abuse
7. **Add monitoring**: Prometheus metrics, health checks
8. **Add CI/CD**: GitHub Actions is already configured

## Resources

- [Go Documentation](https://golang.org/doc/)
- [Effective Go](https://golang.org/doc/effective_go)
- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- [Standard Go Project Layout](https://github.com/golang-standards/project-layout)

## Getting Help

- Check the [README.md](README.md) for detailed documentation
- Review code examples in the test files
- Check Go documentation: `go doc <package>`
