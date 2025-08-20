import 'package:flutter/foundation.dart';

enum JobStatus { queued, inProgress, complete, failed }
enum JobPriority { low, normal, high }

/// A data class representing a single asynchronous background job.
@immutable
class Job {
  final int? id;
  final String jobType;
  final JobStatus status;
  final JobPriority priority;
  final String? requestFingerprint;
  final String requestPayload;
  final String? promptText;
  final String? responsePayload;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Job({
    this.id,
    required this.jobType,
    this.status = JobStatus.queued,
    this.priority = JobPriority.normal,
    this.requestFingerprint,
    required this.requestPayload,
    this.promptText,
    this.responsePayload,
    required this.createdAt,
    this.completedAt,
  });

  /// Converts a Job object into a Map for database insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'job_type': jobType,
      'status': status.name,
      'priority': priority.name,
      'request_fingerprint': requestFingerprint,
      'request_payload': requestPayload,
      'prompt_text': promptText,
      'response_payload': responsePayload,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Creates a Job object from a database map.
  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      id: map['id'],
      jobType: map['job_type'],
      status: JobStatus.values.byName(map['status']),
      priority: JobPriority.values.byName(map['priority']),
      requestFingerprint: map['request_fingerprint'],
      requestPayload: map['request_payload'],
      promptText: map['prompt_text'],
      responsePayload: map['response_payload'],
      createdAt: DateTime.parse(map['created_at']),
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at']) : null,
    );
  }
}