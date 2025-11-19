#!/bin/bash

# Build script for the application

set -e

echo "Building Go application..."

# Set build variables
BUILD_DIR="bin"
BINARY_NAME="api"
MAIN_PATH="cmd/api/main.go"

# Create build directory if it doesn't exist
mkdir -p $BUILD_DIR

# Build the application
go build -o $BUILD_DIR/$BINARY_NAME $MAIN_PATH

echo "Build completed successfully!"
echo "Binary location: $BUILD_DIR/$BINARY_NAME"
