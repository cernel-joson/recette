// lib/core/presentation/screens/job_inspector_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:recette/core/jobs/data/models/job_model.dart';
import 'package:recette/core/jobs/presentation/controllers/job_controller.dart';
import 'package:recette/core/jobs/presentation/controllers/job_inspector_controller.dart';

class JobInspectorScreen extends StatelessWidget {
  final int jobId; // Pass the job ID instead of the whole object

  const JobInspectorScreen({super.key, required this.jobId});

  // --- NEW: Helper method to generate the text for copying ---
  String _getJobDetailsAsText(Job job) {
    final buffer = StringBuffer();
    buffer.writeln('Job Details');
    buffer.writeln('-----------');
    buffer.writeln('ID: ${job.id}');
    buffer.writeln('Type: ${job.jobType}');
    buffer.writeln('Title: ${job.title ?? 'N/A'}');
    buffer.writeln('Status: ${job.status.name}');
    buffer.writeln('Created: ${job.createdAt.toLocal()}');
    buffer.writeln('Completed: ${job.completedAt?.toLocal() ?? 'N/A'}');
    if (job.errorMessage != null) {
      buffer.writeln('Error: ${job.errorMessage}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JobInspectorController(jobId),
      child: Consumer<JobInspectorController>(
        builder: (context, controller, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(controller.job?.title ?? 'Job Inspector'),
            ),
            body: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.error != null
                    ? Center(child: Text(controller.error!))
                    : controller.job == null
                        ? const Center(child: Text('Job data is unavailable.'))
                        : _buildInspectorBody(context, controller),
          );
        },
      ),
    );
  }

  Widget _buildInspectorBody(
      BuildContext context, JobInspectorController controller) {
    final job = controller.job!;
    final textTheme = Theme.of(context).textTheme;// The rest of the UI now uses the fresh 'job' object
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildInfoCard(context, job),
        const SizedBox(height: 16),
        _buildJsonCard(
          context: context,
          title: 'Request Payload',
          jsonString: job.requestPayload,
        ),
        const SizedBox(height: 16),
        _buildJsonCard(
          context: context,
          title: 'Prompt Sent to AI',
          jsonString: job.promptText,
          isJson: false,
        ),
        const SizedBox(height: 16),
        _buildJsonCard(
          context: context,
          title: 'Raw AI Response',
          jsonString: job.rawAiResponse,
          isJson: false,
        ),
        const SizedBox(height: 16),
        _buildJsonCard(
          context: context,
          title: 'Parsed Response Payload',
          jsonString: job.responsePayload,
        ),
      ],
    );
  }
  
  Widget _buildInfoCard(BuildContext context, Job job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Job Details', style: Theme.of(context).textTheme.titleLarge),
                // --- NEW: Add the copy button ---
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy Details',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _getJobDetailsAsText(job)));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Job details copied to clipboard!')),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('ID:', job.id.toString()),
            _buildInfoRow('Type:', job.jobType),
            _buildInfoRow('Title:', job.title ?? 'N/A'),
            _buildInfoRow('Status:', job.status.name),
            _buildInfoRow('Created:', job.createdAt.toLocal().toString()),
            _buildInfoRow('Completed:', job.completedAt?.toLocal().toString() ?? 'N/A'),
            if (job.status == JobStatus.failed && job.errorMessage != null)
              _buildInfoRow('Error:', job.errorMessage!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, softWrap: true)),
        ],
      ),
    );
  }

  // --- THIS IS THE FIX ---
  // The method signature now includes the optional 'isJson' parameter.
  Widget _buildJsonCard({
    required BuildContext context,
    required String title,
    String? jsonString,
    bool isJson = true, // Default to true for backward compatibility
  }) {
    String formattedText = 'No data.';
    if (jsonString != null && jsonString.isNotEmpty) {
      if (isJson) {
        try {
          final decoded = json.decode(jsonString);
          formattedText = const JsonEncoder.withIndent('  ').convert(decoded);
        } catch (e) {
          formattedText = 'Error parsing JSON:\n$jsonString';
        }
      } else {
        // If it's not JSON, just use the string as is.
        formattedText = jsonString;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy to Clipboard',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: formattedText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard!')),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            SelectableText(
              formattedText,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}