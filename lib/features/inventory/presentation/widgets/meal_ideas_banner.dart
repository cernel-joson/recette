// lib/features/inventory/presentation/widgets/meal_ideas_banner.dart
import 'package:flutter/material.dart';
import 'package:recette/core/jobs/job_model.dart';

class MealIdeasBanner extends StatelessWidget {
  final Job job;
  final VoidCallback onView;

  const MealIdeasBanner({
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
        leading: const Icon(Icons.lightbulb_outline, color: Colors.green),
        title: const Text('Your meal ideas are ready!', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Suggestions based on your inventory are available.'),
        trailing: FilledButton(
          onPressed: onView,
          child: const Text('View'),
        ),
      ),
    );
  }
}