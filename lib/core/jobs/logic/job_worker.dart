import 'package:recette/core/jobs/data/models/job_model.dart';
import 'package:recette/core/jobs/data/models/job_result.dart';

/// The abstract "contract" for a class that knows how to execute a specific type of job.
abstract class JobWorker {
  /// Executes the job's logic and returns the raw string response from the backend.
  ///
  /// Throws an exception if the job fails.
  /// Executes the job's logic and returns a JobResult.
  Future<JobResult> execute(Job job);
  
  /// An optional method for the worker to perform cleanup or follow-up
  /// actions after a job's result has been successfully saved.
  Future<void> onComplete(Job job) async {
    // Default implementation does nothing.
  }
}