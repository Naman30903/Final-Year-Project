# HyFND - Hybrid Fake News Detector

Flutter frontend application for detecting fake news using AI/ML models.

## Architecture

This project follows **Clean Architecture** principles with **MVVM** pattern:

```
lib/
├── core/                    # Core utilities & infrastructure
│   ├── constants/          # API & app constants
│   ├── di/                 # Dependency injection
│   ├── error/              # Error handling
│   ├── network/            # API client
│   ├── router/             # Navigation
│   ├── theme/              # App theming
│   └── utils/              # Utilities (logger, etc.)
├── data/                   # Data layer
│   ├── datasources/       # Remote data sources
│   ├── models/            # Data models
│   └── repositories/      # Repository implementations
├── domain/                 # Business logic layer
│   ├── entities/          # Business entities
│   ├── repositories/      # Repository interfaces
│   └── usecases/          # Use cases
├── presentation/          # Presentation layer (MVVM)
│   ├── providers/        # View models (ChangeNotifier)
│   ├── views/            # UI screens
│   └── widgets/          # Reusable widgets
└── main.dart             # Entry point
```

## Features

- ✅ **Clean Architecture** - Clear separation of concerns
- ✅ **MVVM Pattern** - Reactive UI with Provider
- ✅ **Dependency Injection** - GetIt for DI
- ✅ **Type-safe Networking** - Dio with error handling
- ✅ **Navigation** - GoRouter for declarative routing
- ✅ **State Management** - Provider with ChangeNotifier
- ✅ **JSON Serialization** - Automated with json_serializable

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Your backend API running on `http://localhost:8080`

### Installation

1. **Get dependencies**:
```bash
flutter pub get
```

2. **Generate code** (for JSON serialization):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. **Run the app**:
```bash
flutter run
```

### Configuration

Update the API base URL in `lib/core/constants/api_constants.dart`:

```dart
static const String baseUrl = 'http://localhost:8080'; // Change for production
```

## Project Structure Details

### Core Layer
- **constants/**: API endpoints, app constants
- **network/**: Dio-based API client with interceptors
- **error/**: Custom failure classes
- **di/**: GetIt service locator setup
- **router/**: GoRouter configuration
- **theme/**: Material Design theme configuration

### Domain Layer
- **entities/**: Pure Dart objects (Prediction, NewsArticle)
- **repositories/**: Abstract repository interfaces
- **usecases/**: Business logic (AnalyzeNewsUseCase, GetHistoryUseCase)

### Data Layer
- **models/**: Data models extending entities with JSON serialization
- **datasources/**: API communication implementations
- **repositories/**: Repository interface implementations

### Presentation Layer
- **providers/**: ChangeNotifier-based view models
- **views/**: UI screens (Home, Analysis, Result, History)
- **widgets/**: Reusable UI components

## API Integration

The app integrates with your Go backend:

- `POST /api/analyze` - Analyze news article
- `GET /api/predictions?id={id}` - Get prediction by ID
- `GET /api/history` - Get analysis history
- `GET /api/health` - Health check

## Screens

1. **Home** - Welcome screen with navigation
2. **Analysis** - Input form for text/URL analysis
3. **Result** - Display analysis results with confidence score
4. **History** - List of past analyses

## State Management

Using Provider with ChangeNotifier pattern:

```dart
// In main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) => di.sl<NewsAnalysisProvider>(),
    ),
  ],
  // ...
)

// In views
Consumer<NewsAnalysisProvider>(
  builder: (context, provider, child) {
    // Access state here
  },
)
```

## Error Handling

All errors are handled through the `Either<Failure, Success>` pattern using the `dartz` package:

```dart
final result = await analyzeNewsUseCase(article);
result.fold(
  (failure) => // Handle error,
  (prediction) => // Handle success,
);
```

## Development

### Adding New Features

1. Create entity in `domain/entities/`
2. Create use case in `domain/usecases/`
3. Create data model in `data/models/`
4. Update data source in `data/datasources/`
5. Update repository implementation
6. Add to dependency injection in `core/di/`
7. Create/update provider in `presentation/providers/`
8. Build UI in `presentation/views/`

### Running Tests

```bash
flutter test
```

### Code Generation

When you modify models with `@JsonSerializable`:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Dependencies

### Production
- `provider` - State management
- `dio` - HTTP client
- `dartz` - Functional programming (Either)
- `get_it` - Dependency injection
- `go_router` - Declarative routing
- `json_annotation` - JSON serialization annotations
- `logger` - Logging
- `shared_preferences` - Local storage

### Development
- `build_runner` - Code generation
- `json_serializable` - JSON serialization generator
- `flutter_lints` - Linting rules

## Environment Variables

For different environments, you can pass `--dart-define`:

```bash
flutter run --dart-define=ENV=production
```

## Troubleshooting

### API Connection Issues
- Ensure backend is running on `http://localhost:8080`
- Check `api_constants.dart` for correct URL
- For iOS simulator, use `http://localhost:8080`
- For Android emulator, use `http://10.0.2.2:8080`

### Build Issues
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

## License

Copyright © 2025 HyFND Team
