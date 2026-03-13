import 'package:flutter/material.dart';
import '../../domain/entities/prediction.dart';

class PredictionCard extends StatelessWidget {
  final Prediction prediction;

  const PredictionCard({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final isFake = prediction.isFake;
    final color = isFake ? Colors.red : Colors.green;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isFake ? Icons.warning_amber : Icons.verified,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  prediction.result.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(prediction.confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            if (prediction.hasMetadata) ...[
              const SizedBox(height: 8),
              Text(
                prediction.articleTitle ?? '',
                style: const TextStyle(fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (prediction.articleSource != null)
                Text(
                  prediction.articleSource!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
