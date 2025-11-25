import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/news_analysis_provider.dart';

class ResultView extends StatelessWidget {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NewsAnalysisProvider>(
      builder: (context, provider, child) {
        final prediction = provider.currentPrediction;

        if (prediction == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Result')),
            body: const Center(
              child: Text('No results available'),
            ),
          );
        }

        final isFake = prediction.isFake;
        final resultColor = isFake ? Colors.red : Colors.green;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Analysis Result'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  color: resultColor.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          isFake ? Icons.warning_amber : Icons.verified,
                          size: 80,
                          color: resultColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          prediction.result.toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: resultColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isFake
                              ? 'This article appears to be fake news'
                              : 'This article appears to be genuine',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Confidence Score',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: prediction.confidence,
                          backgroundColor: Colors.grey.shade300,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(resultColor),
                          minHeight: 12,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(prediction.confidence * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: resultColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          provider.clearCurrentPrediction();
                          context.go('/analyze');
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Analyze Another'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/history'),
                        icon: const Icon(Icons.history),
                        label: const Text('View History'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
