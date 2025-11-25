import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_analysis_provider.dart';
import '../widgets/loading_indicator.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsAnalysisProvider>().loadHistory();
    });
  }

  Future<void> _refreshHistory() async {
    await context.read<NewsAnalysisProvider>().loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<NewsAnalysisProvider>(
        builder: (context, provider, child) {
          if (provider.state == AnalysisState.loading) {
            return const LoadingIndicator(message: 'Loading history...');
          }

          final history = provider.history;

          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No analysis history yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Analyze some articles to see them here',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshHistory,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final prediction = history[index];
                final isFake = prediction.isFake;
                final resultColor = isFake ? Colors.red : Colors.green;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      isFake ? Icons.warning_amber : Icons.verified,
                      color: resultColor,
                    ),
                    title: Text(
                      prediction.result.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: resultColor,
                      ),
                    ),
                    subtitle: Text(
                      'Confidence: ${(prediction.confidence * 100).toStringAsFixed(1)}%',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
