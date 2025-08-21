// lib/core/presentation/screens/job_inspector_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recette/core/jobs/data/models/job_model.dart';

class JobInspectorScreen extends StatelessWidget {
  final Job job;
  const JobInspectorScreen({super.key, required this.job});

  // --- NEW: Helper method to generate the text for copying ---
  String _getJobDetailsAsText() {
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Job Inspector #${job.id}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildInfoCard(context),
          const SizedBox(height: 16),
          _buildJsonCard(
            context: context,
            title: 'Request Payload',
            jsonString: job.requestPayload,
          ),
          const SizedBox(height: 16),
          _buildJsonCard(
            context: context,
            title: 'Response Payload',
            jsonString: job.responsePayload,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(BuildContext context) {
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
                    Clipboard.setData(ClipboardData(text: _getJobDetailsAsText()));
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

  Widget _buildJsonCard({
    required BuildContext context,
    required String title,
    String? jsonString,
  }) {
    String formattedJson = 'No data.';
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final decoded = json.decode(jsonString);
        formattedJson = const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (e) {
        formattedJson = 'Error parsing JSON:\n$jsonString';
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
                    Clipboard.setData(ClipboardData(text: formattedJson));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard!')),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            SelectableText(
              formattedJson,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}