import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:recette/core/jobs/job_manager.dart';
import 'package:recette/features/dietary_profile/data/models/dietary_profile_model.dart';
import 'package:recette/features/dietary_profile/services/profile_service.dart';

class DietaryProfileController with ChangeNotifier {
  final JobManager _jobManager;

  // State
  final TextEditingController textController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  // Public getters for the UI to read state
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  DietaryProfileController({
    JobManager? jobManager,
  }) : _jobManager = jobManager ?? JobManager.instance;

  /// Loads the user's profile from shared preferences.
  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();
    final profile = await ProfileService.loadProfile();
    textController.text = profile.markdownText;
    _isLoading = false;
    notifyListeners();
  }

  /// Saves the current profile text to shared preferences.
  Future<void> saveProfile() async {
    _isSaving = true;
    notifyListeners();
    final newProfile = DietaryProfile(markdownText: textController.text);
    await ProfileService.saveProfile(newProfile);
    _isSaving = false;
    notifyListeners();
  }

  /// Submits a background job to have the AI review the profile.
  /// Returns true if a job was started, false otherwise.
  Future<bool> runAiReview() async {
    if (textController.text.trim().isEmpty) {
      return false; 
    }
    final requestPayload = json.encode({'profile_text': textController.text});
    await _jobManager.submitJob(
      jobType: 'profile_review',
      requestPayload: requestPayload,
    );
    return true;
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}