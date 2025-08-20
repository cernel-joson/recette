import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/core/jobs/job_controller.dart';
import 'package:recette/core/jobs/job_model.dart';

class JobsTrayScreen extends StatelessWidget {
  const JobsTrayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job History'),
      ),
      body: Consumer<JobController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.jobs.isEmpty) {
            return const Center(
              child: Text(
                'No recent jobs to display.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: controller.jobs.length,
            itemBuilder: (context, index) {
              final job = controller.jobs[index];
              return _JobListItem(job: job);
            },
          );
        },
      ),
    );
  }
}

/// A helper widget to display a single job in the list.
class _JobListItem extends StatelessWidget {
  final Job job;

  const _JobListItem({required this.job});

  // Helper to get the right icon for each status
  IconData _getStatusIcon(JobStatus status) {
    switch (status) {
      case JobStatus.queued:
        return Icons.hourglass_top_rounded;
      case JobStatus.inProgress:
        return Icons.sync;
      case JobStatus.complete:
        return Icons.check_circle_outline_rounded;
      case JobStatus.failed:
        return Icons.error_outline_rounded;
      case JobStatus.archived:
        return Icons.history_rounded; // Add an icon for the archived state
    }
  }

  // Helper to get the right color for each status
  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.queued:
        return Colors.blue;
      case JobStatus.inProgress:
        return Colors.orange;
      case JobStatus.complete:
        return Colors.green;
      case JobStatus.failed:
        return Colors.red;
      case JobStatus.archived:
        return Colors.grey;
    }
  }

  // A simple title generator based on job type
  String _getJobTitle(Job job) {
    // In a real app, you'd have a more sophisticated mapping here.
    String title;

    switch (job.jobType) {
      case 'recipe_parsing':
        title = 'Parse New Recipe';
      case 'meal_suggestion':
        title = 'Generate Meal Ideas';
      default:
        title = job.jobType.replaceAll('_', ' ').toUpperCase();
    }

    return '${title}: ${(job.title ?? 'Job #${job.id}')}';
  }

  void _onTap(BuildContext context) {
    if (![JobStatus.complete, JobStatus.archived].contains(job.status) || job.responsePayload == null) {
      return; // Only completed jobs with a response can be replayed
    }
    
    // For now, we'll just show the raw JSON response in a dialog.
    // In the future, this would trigger a more sophisticated "replay" action.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Job Result'),
        content: SingleChildScrollView(
          child: Text(
            const JsonEncoder.withIndent('  ').convert(json.decode(job.responsePayload!)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(
          _getStatusIcon(job.status),
          color: _getStatusColor(job.status),
        ),
        title: Text(_getJobTitle(job), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Status: ${job.status.name}\nCreated: ${job.createdAt.toLocal()}'),
        isThreeLine: true,
        onTap: () => _onTap(context),
      ),
    );
  }
}