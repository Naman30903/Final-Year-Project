import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/prediction.dart';
import '../repositories/news_repository.dart';

class GetHistoryUseCase {
  final NewsRepository repository;

  GetHistoryUseCase(this.repository);

  Future<Either<Failure, List<Prediction>>> call() async {
    return await repository.getHistory();
  }
}
