import 'package:go_router/go_router.dart';
import '../../presentation/views/home_view.dart';
import '../../presentation/views/analysis_view.dart';
import '../../presentation/views/history_view.dart';
import '../../presentation/views/result_view.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: '/analyze',
        name: 'analyze',
        builder: (context, state) => const AnalysisView(),
      ),
      GoRoute(
        path: '/result',
        name: 'result',
        builder: (context, state) => const ResultView(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryView(),
      ),
    ],
  );
}
