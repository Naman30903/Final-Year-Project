import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/entities/prediction.dart';
import '../../domain/repositories/news_repository.dart';
import '../datasources/news_remote_datasource.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsRemoteDataSource remoteDataSource;

  NewsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, Prediction>> analyzeNews(NewsArticle article) async {
    try {
      final result = await remoteDataSource.analyzeNews({
        'type': article.type,
        'content': article.content,
      });
      return Right(result);
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Prediction>> getPrediction(String id) async {
    try {
      final result = await remoteDataSource.getPrediction(id);
      return Right(result);
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Prediction>>> getHistory() async {
    try {
      final result = await remoteDataSource.getHistory();
      return Right(result);
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkHealth() async {
    try {
      final result = await remoteDataSource.checkHealth();
      return Right(result);
    } on Exception catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }
}
