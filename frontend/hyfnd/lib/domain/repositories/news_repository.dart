import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/news_article.dart';
import '../entities/prediction.dart';

abstract class NewsRepository {
  Future<Either<Failure, Prediction>> analyzeNews(NewsArticle article);
  Future<Either<Failure, Prediction>> getPrediction(String id);
  Future<Either<Failure, List<Prediction>>> getHistory();
  Future<Either<Failure, bool>> checkHealth();
}
