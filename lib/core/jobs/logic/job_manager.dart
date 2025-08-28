import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:recette/core/jobs/data/models/job_model.dart';
import 'package:recette/core/jobs/data/repositories/job_repository.dart';
import 'package:recette/core/jobs/logic/job_worker.dart';
import 'package:recette/core/jobs/data/models/job_result.dart';

class JobManager {
  // --- Singleton Implementation ---
  static final JobManager _instance = JobManager._internal(JobRepository());
  static JobManager get instance => _instance;

  final JobRepository _jobRepository;
  final Map<String, JobWorker> _workers = {};
  bool _isProcessing = false;

  @visibleForTesting
  JobManager.internal(this._jobRepository); // Internal constructor for testing

  // Private constructor for the singleton
  JobManager._internal(this._jobRepository);

  /// Registers a worker to handle a specific job type.
  void registerWorker(String jobType, JobWorker worker) {
    _workers[jobType] = worker;
  }

  /// The main entry point for submitting a new job to the system.
  Future<Job> submitJob({
    required String jobType,
    required String requestPayload,
    JobPriority priority = JobPriority.normal,
  }) async {
    final createdJob = _jobRepository.createJob(
      jobType: jobType,
      requestPayload: requestPayload,
      priority: priority,
    );

    _startProcessing(); // Start the queue processor
    return createdJob;
  }

  /// Starts processing the job queue if it's not already running.
  Future<void> _startProcessing() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      Job? nextJob;
      // Loop until there are no more queued jobs
      while ((nextJob = await _jobRepository.getNextQueuedJob()) != null) {
        final job = nextJob!;
        final worker = _workers[job.jobType];

        if (worker != null) {
          try {
            await _jobRepository.updateJobStatus(job.id!, JobStatus.inProgress);
            final JobResult result = await worker.execute(job);
            await _jobRepository.completeJob(job.id!, result);
            
            final completedJob = await _jobRepository.getJobById(job.id!);
            if (completedJob != null) {
              await worker.onComplete(completedJob);
            }
          } catch (e) {
            debugPrint('Job failed: $e');
            // Instead of just updating the status, call the failJob method
            // to save the specific error message to the database.
            await _jobRepository.failJob(job.id!, e.toString());
          }
        } else {
          // Handle case where no worker is registered for a job type
          // throw Exception('No worker found for job type: ${job.jobType}');
          await _jobRepository.failJob(job.id!, 'No worker found for job type: ${job.jobType}');
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> archiveJob(int jobId) async {
    await _jobRepository.updateJobStatus(jobId, JobStatus.archived);
  }
}