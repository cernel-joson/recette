import 'package:flutter_test/flutter_test.dart';
import 'package:recette/core/jobs/data/models/job_model.dart';

void main() {
  group('Job Model', () {
    final now = DateTime.now();
    final testJob = Job(
      id: 1,
      jobType: 'test_job',
      status: JobStatus.complete,
      priority: JobPriority.high,
      requestFingerprint: 'fingerprint123',
      requestPayload: '{"key":"value"}',
      promptText: 'This is a test prompt.',
      responsePayload: '{"result":"success"}',
      createdAt: now,
      completedAt: now.add(const Duration(seconds: 5)),
    );

    test('toMap serializes correctly', () {
      final map = testJob.toMap();

      expect(map['id'], 1);
      expect(map['job_type'], 'test_job');
      expect(map['status'], 'complete');
      expect(map['priority'], 'high');
      expect(map['request_fingerprint'], 'fingerprint123');
      expect(map['request_payload'], '{"key":"value"}');
      expect(map['prompt_text'], 'This is a test prompt.');
      expect(map['response_payload'], '{"result":"success"}');
      expect(map['created_at'], now.toIso8601String());
      expect(map['completed_at'], now.add(const Duration(seconds: 5)).toIso8601String());
    });

    test('fromMap deserializes correctly', () {
      final map = {
        'id': 1,
        'job_type': 'test_job',
        'status': 'complete',
        'priority': 'high',
        'request_fingerprint': 'fingerprint123',
        'request_payload': '{"key":"value"}',
        'prompt_text': 'This is a test prompt.',
        'response_payload': '{"result":"success"}',
        'created_at': now.toIso8601String(),
        'completed_at': now.add(const Duration(seconds: 5)).toIso8601String(),
      };

      final job = Job.fromMap(map);

      expect(job.id, 1);
      expect(job.jobType, 'test_job');
      expect(job.status, JobStatus.complete);
      expect(job.priority, JobPriority.high);
      expect(job.requestFingerprint, 'fingerprint123');
      expect(job.requestPayload, '{"key":"value"}');
      expect(job.promptText, 'This is a test prompt.');
      expect(job.responsePayload, '{"result":"success"}');
      expect(job.createdAt, now);
      expect(job.completedAt, now.add(const Duration(seconds: 5)));
    });

    test('fromMap handles null values correctly', () {
      final map = {
        'id': 2,
        'job_type': 'another_job',
        'status': 'queued',
        'priority': 'low',
        'request_payload': '{}',
        'created_at': now.toIso8601String(),
        // All optional fields are null
        'request_fingerprint': null,
        'prompt_text': null,
        'response_payload': null,
        'completed_at': null,
      };

      final job = Job.fromMap(map);

      expect(job.id, 2);
      expect(job.status, JobStatus.queued);
      expect(job.priority, JobPriority.low);
      expect(job.requestFingerprint, isNull);
      expect(job.responsePayload, isNull);
      expect(job.completedAt, isNull);
    });
  });
}