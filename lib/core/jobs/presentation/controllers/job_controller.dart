import 'package:flutter/foundation.dart';
import 'package:recette/core/jobs/data/models/job_model.dart';
import 'package:recette/core/jobs/data/repositories/job_repository.dart';

class JobController with ChangeNotifier {
  final JobRepository _jobRepository;

  JobController({JobRepository? jobRepository})
      : _jobRepository = jobRepository ?? JobRepository() {
    loadJobs();
  }

  bool _isLoading = true;
  List<Job> _jobs = [];

  bool get isLoading => _isLoading;
  List<Job> get jobs => _jobs;

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
}