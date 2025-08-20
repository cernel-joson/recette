import 'package:flutter/material.dart';
import 'package:recette/core/jobs/job_model.dart';

class PendingJobBanner extends StatelessWidget {
  final Job job;
  final VoidCallback onView;

  const PendingJobBanner({
    super.key,
    required this.job,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green[50],
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline, color: Colors.green),
        title: const Text('A new recipe is ready!', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('"${job.promptText ?? 'Your recipe'}" has been parsed.'),
        trailing: FilledButton(
          onPressed: onView,
          child: const Text('Review'),
        ),
      ),
    );
  }
}