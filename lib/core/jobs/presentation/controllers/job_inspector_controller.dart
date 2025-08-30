import 'package:flutter/foundation.dart';
import 'package:recette/core/jobs/data/models/job_model.dart';
import 'package:recette/core/jobs/data/repositories/job_repository.dart';

class JobInspectorController with ChangeNotifier {
  final JobRepository _repository;
  final int _jobId;

  Job? _job;
  bool _isLoading = false;
  String? _error;

  JobInspectorController(this._jobId, {JobRepository? repository})
      : _repository = repository ?? JobRepository() {
    loadJobDetails();
  }

  Job? get job => _job;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadJobDetails() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _job = await _repository.getJobById(_jobId);
      if (_job == null) {
        _error = 'Job not found.';
      }
    } catch (e) {
      _error = 'Failed to load job details: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}