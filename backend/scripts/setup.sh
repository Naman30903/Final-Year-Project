#!/bin/bash

# Development setup script

set -e

echo "Setting up development environment..."

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "Go is not installed. Please install Go 1.21 or higher."
    exit 1
fi

echo "Go version: $(go version)"

# Install dependencies
echo "Installing dependencies..."
go mod download
go mod tidy

# Create necessary directories
echo "Creating directories..."
mkdir -p bin
mkdir -p logs
mkdir -p tmp

# Copy environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo "Please update .env with your configuration"
fi

echo "Setup completed successfully!"
echo ""
echo "Quick start commands:"
echo "  make run    - Run the application"
echo "  make test   - Run tests"
echo "  make build  - Build the application"
