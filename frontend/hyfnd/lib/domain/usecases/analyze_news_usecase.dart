import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/news_article.dart';
import '../entities/prediction.dart';
import '../repositories/news_repository.dart';

class AnalyzeNewsUseCase {
  final NewsRepository repository;

  AnalyzeNewsUseCase(this.repository);

  Future<Either<Failure, Prediction>> call(NewsArticle article) async {
    // Validation
    if (article.content.trim().isEmpty) {
      return const Left(ValidationFailure('Content cannot be empty'));
    }

    if (article.content.length < 50) {
      return const Left(
          ValidationFailure('Content too short (minimum 50 characters)'));
    }

    return await repository.analyzeNews(article);
  }
}
