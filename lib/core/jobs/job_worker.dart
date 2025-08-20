import 'package:recette/core/jobs/job_model.dart';

/// The abstract "contract" for a class that knows how to execute a specific type of job.
abstract class JobWorker {
  /// Executes the job's logic and returns the raw string response from the backend.
  ///
  /// Throws an exception if the job fails.
  Future<String> execute(Job job);
}