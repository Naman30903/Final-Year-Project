import 'package:flutter/foundation.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/entities/prediction.dart';
import '../../domain/usecases/analyze_news_usecase.dart';
import '../../domain/usecases/get_history_usecase.dart';

enum AnalysisState { initial, loading, success, error }

class NewsAnalysisProvider extends ChangeNotifier {
  final AnalyzeNewsUseCase analyzeNewsUseCase;
  final GetHistoryUseCase getHistoryUseCase;

  NewsAnalysisProvider({
    required this.analyzeNewsUseCase,
    required this.getHistoryUseCase,
  });

  AnalysisState _state = AnalysisState.initial;
  Prediction? _currentPrediction;
  List<Prediction> _history = [];
  String? _errorMessage;

  AnalysisState get state => _state;
  Prediction? get currentPrediction => _currentPrediction;
  List<Prediction> get history => _history;
  String? get errorMessage => _errorMessage;

  Future<void> analyzeNews(String content, String type) async {
    _state = AnalysisState.loading;
    _errorMessage = null;
    notifyListeners();

    final article = NewsArticle(content: content, type: type);
    final result = await analyzeNewsUseCase(article);

    result.fold(
      (failure) {
        _state = AnalysisState.error;
        _errorMessage = _mapFailureToMessage(failure);
        notifyListeners();
      },
      (prediction) {
        _state = AnalysisState.success;
        _currentPrediction = prediction;
        notifyListeners();
      },
    );
  }

  Future<void> loadHistory() async {
    final result = await getHistoryUseCase();

    result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
      },
      (predictions) {
        _history = predictions;
      },
    );
    notifyListeners();
  }

  void clearCurrentPrediction() {
    _currentPrediction = null;
    _state = AnalysisState.initial;
    notifyListeners();
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'No internet connection';
    } else if (failure is ValidationFailure) {
      return failure.message;
    } else {
      return 'Unexpected error occurred';
    }
  }
}
