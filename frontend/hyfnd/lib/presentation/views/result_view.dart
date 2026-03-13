import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/prediction.dart';
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
            body: const Center(child: Text('No results available')),
          );
        }

        final isFake = prediction.isFake;
        final resultColor = isFake ? Colors.red : Colors.green;
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(title: const Text('Analysis Result')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Verdict card ──
                _VerdictCard(prediction: prediction, color: resultColor),

                const SizedBox(height: 16),

                // ── Probability breakdown ──
                _ProbabilityCard(prediction: prediction),

                // ── Article metadata (URL requests only) ──
                if (prediction.hasMetadata) ...[
                  const SizedBox(height: 16),
                  _MetadataCard(prediction: prediction),
                ],

                const SizedBox(height: 16),

                // ── Details card ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Details',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _DetailRow(
                          label: 'Input Type',
                          value: prediction.requestType.toUpperCase(),
                        ),
                        _DetailRow(
                          label: 'Model',
                          value: prediction.modelVersion,
                        ),
                        _DetailRow(
                          label: 'Processing Time',
                          value: '${prediction.processingTime} ms',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Actions ──
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

// ── Verdict ──────────────────────────────────────────────────────────────

class _VerdictCard extends StatelessWidget {
  final Prediction prediction;
  final Color color;

  const _VerdictCard({required this.prediction, required this.color});

  @override
  Widget build(BuildContext context) {
    final isFake = prediction.isFake;

    return Card(
      elevation: 4,
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              isFake ? Icons.warning_amber : Icons.verified,
              size: 80,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              prediction.result.toUpperCase(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
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
            const SizedBox(height: 12),
            Text(
              '${(prediction.confidence * 100).toStringAsFixed(1)}% confident',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Probability breakdown ────────────────────────────────────────────────

class _ProbabilityCard extends StatelessWidget {
  final Prediction prediction;

  const _ProbabilityCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fakePct = (prediction.fakeProbability * 100);
    final realPct = (prediction.realProbability * 100);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Probability Breakdown',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Fake bar
            _ProbBar(
              label: 'Fake',
              value: prediction.fakeProbability,
              pctText: '${fakePct.toStringAsFixed(1)}%',
              color: Colors.red,
            ),
            const SizedBox(height: 12),

            // Real bar
            _ProbBar(
              label: 'Real',
              value: prediction.realProbability,
              pctText: '${realPct.toStringAsFixed(1)}%',
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProbBar extends StatelessWidget {
  final String label;
  final double value;
  final String pctText;
  final Color color;

  const _ProbBar({
    required this.label,
    required this.value,
    required this.pctText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            Text(pctText,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}

// ── Article metadata ─────────────────────────────────────────────────────

class _MetadataCard extends StatelessWidget {
  final Prediction prediction;

  const _MetadataCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.language,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Article Info',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (prediction.articleTitle != null &&
                prediction.articleTitle!.isNotEmpty)
              _DetailRow(label: 'Title', value: prediction.articleTitle!),
            if (prediction.articleSource != null &&
                prediction.articleSource!.isNotEmpty)
              _DetailRow(label: 'Source', value: prediction.articleSource!),
            if (prediction.articleAuthor != null &&
                prediction.articleAuthor!.isNotEmpty)
              _DetailRow(label: 'Author', value: prediction.articleAuthor!),
            if (prediction.articleDescription != null &&
                prediction.articleDescription!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  prediction.articleDescription!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Shared detail row ────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
