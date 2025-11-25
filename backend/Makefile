.PHONY: build run test clean lint coverage deps help

# Build the application
build:
	@echo "Building..."
	go build -o bin/api cmd/api/main.go

# Run the application
run:
	@echo "Running..."
	go run cmd/api/main.go

# Run tests
test:
	@echo "Running tests..."
	go test -v -race -coverprofile=coverage.out ./...

# Generate coverage report
coverage:
	@echo "Generating coverage report..."
	go tool cover -html=coverage.out

# Clean build artifacts
clean:
	@echo "Cleaning..."
	rm -rf bin/
	rm -f coverage.out

# Run linter
lint:
	@echo "Running linter..."
	golangci-lint run

# Download dependencies
deps:
	@echo "Downloading dependencies..."
	go mod download
	go mod tidy

# Display help
help:
	@echo "Available targets:"
	@echo "  build    - Build the application"
	@echo "  run      - Run the application"
	@echo "  test     - Run tests"
	@echo "  coverage - Generate coverage report"
	@echo "  clean    - Clean build artifacts"
	@echo "  lint     - Run linter"
	@echo "  deps     - Download dependencies"

.DEFAULT_GOAL := build
