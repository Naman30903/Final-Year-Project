import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/news_article.dart';
import '../entities/prediction.dart';
import '../repositories/news_repository.dart';

class AnalyzeNewsUseCase {
  final NewsRepository repository;

  AnalyzeNewsUseCase(this.repository);

  Future<Either<Failure, Prediction>> call(NewsArticle article) async {
    if (article.content.trim().isEmpty) {
      return const Left(ValidationFailure('Content cannot be empty'));
    }

    // Only enforce minimum length for text input, not URLs.
    if (article.type == 'text' && article.content.trim().length < 50) {
      return const Left(
          ValidationFailure('Content too short (minimum 50 characters)'));
    }

    if (article.type == 'url') {
      final uri = Uri.tryParse(article.content.trim());
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        return const Left(ValidationFailure('Please enter a valid URL'));
      }
    }

    return await repository.analyzeNews(article);
  }
}
