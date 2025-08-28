import 'package:flutter/foundation.dart';
import 'package:recette/core/jobs/data/models/job_model.dart';
import 'package:recette/core/jobs/data/repositories/job_repository.dart';
import 'package:recette/core/jobs/logic/job_broadcast_service.dart';

class JobController with ChangeNotifier {
  final JobRepository _jobRepository;
  List<Job> _jobs = [];
  bool _isLoading = true;

  JobController({JobRepository? jobRepository})
      : _jobRepository = jobRepository ?? JobRepository() {
    JobBroadcastService.instance.addListener(loadJobs);
    loadJobs();
  }
  
  List<Job> get jobs => _jobs;
  bool get isLoading => _isLoading;

  /// A computed property that makes it easy for the UI to know if any
  /// jobs are currently being processed.
  bool get hasActiveJobs =>
      _jobs.any((job) => job.status == JobStatus.queued || job.status == JobStatus.inProgress);

  /// Fetches the initial list of jobs from the repository.
  Future<void> loadJobs() async {
    _isLoading = true;
    notifyListeners();
    _jobs = await _jobRepository.getAllJobs();
    _isLoading = false;
    notifyListeners();
  }

  /// Deletes all completed or failed jobs from the database.
  /* Future<void> clearHistory() async {
    await _jobRepository.deleteCompleted();
    await loadJobs(); // <-- Reload the list to reflect the changes
  } */
 
  @override
  void dispose() {
    JobBroadcastService.instance.removeListener(loadJobs);
    super.dispose();
  }
}