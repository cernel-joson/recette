import 'package:flutter/material.dart';
import 'package:recette/core/jobs/job_model.dart';

class PendingJobBanner extends StatelessWidget {
  final Job job;
  final VoidCallback onView;
  final VoidCallback onDismiss;

  const PendingJobBanner({
    super.key,
    required this.job,
    required this.onView,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap with Dismissible for swipe gesture
    return Dismissible(
      key: Key('job_banner_${job.id}'),
      onDismissed: (_) => onDismiss(),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        color: Colors.green[50],
        margin: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: const Icon(Icons.check_circle_outline, color: Colors.green),
          title: const Text('A new recipe is ready!', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('"${job.title ?? 'Your recipe'}" has been parsed.'),
          trailing: Row( // Use a Row for multiple buttons
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: onView,
                child: const Text('Review'),
              ),
              IconButton( // Add a close button
                icon: const Icon(Icons.close),
                onPressed: onDismiss,
                tooltip: 'Dismiss',
              ),
            ],
          ),
        ),
      ),
    );
  }
}