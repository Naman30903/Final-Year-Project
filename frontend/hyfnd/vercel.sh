#!/bin/bash

# Exit on any error
set -e

# Clone the Flutter stable branch
echo ">>> Cloning Flutter SDK (stable)..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# Add Flutter to PATH
export PATH="$PATH:$(pwd)/flutter/bin"

# Pre-cache web artifacts
echo ">>> Running Flutter precache for web..."
flutter precache --web

# Show Flutter version for build logs
flutter --version

# Clean and build
echo ">>> Cleaning project..."
flutter clean

echo ">>> Getting dependencies..."
flutter pub get

echo ">>> Building web release..."
flutter build web --release

echo ">>> Build complete! Output in build/web/"
