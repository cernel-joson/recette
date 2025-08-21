import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:recette/core/jobs/presentation/controllers/job_controller.dart';
import 'package:recette/core/jobs/data/models/job_model.dart';
import 'package:recette/core/jobs/data/repositories/job_repository.dart';
import 'package:recette/core/jobs/logic/job_worker.dart';
import 'package:recette/core/jobs/data/models/job_result.dart';

class JobManager {
  final JobRepository _jobRepository;
  final JobController _jobController;
  final Map<String, JobWorker> _workers;

  JobManager({
    required JobRepository jobRepository,
    required JobController jobController,
    required Map<String, JobWorker> workers,
  })  : _jobRepository = jobRepository,
        _jobController = jobController,
        _workers = workers;

  final List<Job> _queue = [];
  bool _isProcessing = false;

  /// The main entry point for submitting a new job to the system.
  Future<Job> submitJob({
    required String jobType,
    required String requestPayload,
    JobPriority priority = JobPriority.normal,
  }) async {
    final job = await _jobRepository.createJob(
      jobType: jobType,
      requestPayload: requestPayload,
      priority: priority,
    );

    // Add to the in-memory queue and start processing if not already running.
    _queue.add(job);
    _jobController.loadJobs(); // Notify UI of the new "queued" job
    _processQueue();

    return job;
  }

  /// The core processing loop.
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) {
      return;
    }

    _isProcessing = true;
    
    // For now, we process in FIFO order. Prioritization can be added here.
    final job = _queue.removeAt(0);

    try {
      // 1. Find the correct worker for this job type.
      final worker = _workers[job.jobType];
      if (worker == null) {
        throw Exception('No worker found for job type: ${job.jobType}');
      }

      // 2. Mark the job as in-progress.
      await _jobRepository.updateJobStatus(job.id!, JobStatus.inProgress);
      _jobController.loadJobs();

      // 3. Delegate execution to the worker.
      final JobResult result = await worker.execute(job);

      // 4. Mark the job as complete, now passing the full result.
      await _jobRepository.completeJob(job.id!, result);
    } catch (e) {
      debugPrint('Job failed: $e');
      await _jobRepository.updateJobStatus(job.id!, JobStatus.failed);
    } finally {
      // 5. Notify the UI and allow the next job to run.
      _jobController.loadJobs();
      _isProcessing = false;
      // Check if there are more jobs to process.
      _processQueue();
    }
  }
}