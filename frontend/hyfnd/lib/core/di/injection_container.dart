import 'package:get_it/get_it.dart';
import 'package:hyfnd/presentation/services/connection_service.dart';
import '../../data/datasources/news_remote_datasource.dart';
import '../../data/repositories/news_repository_impl.dart';
import '../../domain/repositories/news_repository.dart';
import '../../domain/usecases/analyze_news_usecase.dart';
import '../../domain/usecases/get_history_usecase.dart';
import '../../presentation/providers/news_analysis_provider.dart';
import '../network/api_client.dart';
import '../services/connection_service.dart';
import '../constants/api_constants.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Print API configuration in debug mode
  ApiConstants.printConfiguration();

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

  // Services
  sl.registerLazySingleton(() => ConnectionService(sl()));

  // Core
  sl.registerLazySingleton(() => ApiClient());
}
