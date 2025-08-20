import 'package:recette/core/jobs/job_model.dart';
import 'package:recette/core/jobs/job_result.dart';

/// The abstract "contract" for a class that knows how to execute a specific type of job.
abstract class JobWorker {
  /// Executes the job's logic and returns the raw string response from the backend.
  ///
  /// Throws an exception if the job fails.
  /// Executes the job's logic and returns a JobResult.
  Future<JobResult> execute(Job job);
}