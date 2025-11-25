import 'package:get_it/get_it.dart';
import '../../data/datasources/news_remote_datasource.dart';
import '../../data/repositories/news_repository_impl.dart';
import '../../domain/repositories/news_repository.dart';
import '../../domain/usecases/analyze_news_usecase.dart';
import '../../domain/usecases/get_history_usecase.dart';
import '../../presentation/providers/news_analysis_provider.dart';
import '../network/api_client.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Providers
  sl.registerFactory(
    () => NewsAnalysisProvider(
      analyzeNewsUseCase: sl(),
      getHistoryUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => AnalyzeNewsUseCase(sl()));
  sl.registerLazySingleton(() => GetHistoryUseCase(sl()));

  // Repository
  sl.registerLazySingleton<NewsRepository>(
    () => NewsRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<NewsRemoteDataSource>(
    () => NewsRemoteDataSourceImpl(sl()),
  );

  // Core
  sl.registerLazySingleton(() => ApiClient());
}
