// lib/features/inventory/presentation/screens/meal_ideas_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/core/jobs/job_model.dart';
import 'package:recette/core/jobs/job_repository.dart';
import 'package:recette/core/presentation/controllers/job_controller.dart';

class MealIdeasScreen extends StatelessWidget {
  final Job job;
  const MealIdeasScreen({super.key, required this.job});

  Future<void> _archiveJob(BuildContext context) async {
    final jobRepo = JobRepository();
    await jobRepo.updateJobStatus(job.id!, JobStatus.archived);
    if (context.mounted) {
      // Refresh the job list and pop the screen
      Provider.of<JobController>(context, listen: false).loadJobs();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ideas = json.decode(job.responsePayload!) as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Ideas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => _archiveJob(context),
            tooltip: 'Archive Suggestions',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: ideas.length,
        itemBuilder: (context, index) {
          final idea = ideas[index] as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(idea['title'] ?? 'No Title'),
              subtitle: Text(idea['description'] ?? 'No Description'),
              // In the future, this could trigger another job to generate the full recipe
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generating full recipe is not yet implemented.')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}