// lib/features/dietary_profile/presentation/screens/dietary_profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/core/jobs/logic/job_manager.dart';
import 'package:recette/features/dietary_profile/data/services/profile_service.dart';
import 'package:recette/features/dietary_profile/data/models/dietary_profile_model.dart';
import 'profile_review_screen.dart';

class DietaryProfileScreen extends StatefulWidget {
  const DietaryProfileScreen({super.key});

  @override
  State<DietaryProfileScreen> createState() => _DietaryProfileScreenState();
}

class _DietaryProfileScreenState extends State<DietaryProfileScreen> {
  final _rulesController = TextEditingController();
  final _preferencesController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; });
    final profile = await ProfileService.loadProfile();
    if (mounted) {
      setState(() {
        _rulesController.text = profile.rules;
        _preferencesController.text = profile.preferences;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() { _isSaving = true; });

    final newProfile = DietaryProfile(
      rules: _rulesController.text,
      preferences: _preferencesController.text,
    );

    await ProfileService.saveProfile(newProfile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green),
      );
    }
    setState(() { _isSaving = false; });
  }
  
  Future<void> _runAiReview() async {
    final jobManager = Provider.of<JobManager>(context, listen: false);
    final profile = DietaryProfile(
      rules: _rulesController.text,
      preferences: _preferencesController.text,
    );

    if (profile.fullProfileText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile is empty. Nothing to review.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final requestPayload = json.encode({
      'profile_text': profile.fullProfileText,
    });

    await jobManager.submitJob(
      jobType: 'profile_review',
      requestPayload: requestPayload,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI review started... Track progress in the Jobs Tray.'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }


  @override
  void dispose() {
    _rulesController.dispose();
    _preferencesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dietary Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section for Health Rules
                  const Text(
                    'Health Rules & Allergies',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Enter non-negotiable medical directives and allergies. The AI will treat these as hard constraints.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rulesController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'e.g., "I am diabetic and must avoid sugar. Low-sodium diet required (<2000mg/day). Allergic to peanuts."',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section for Likes and Preferences
                  const Text(
                    'Likes, Dislikes & Preferences',
                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Enter your personal tastes. The AI will treat these as soft suggestions.',
                     style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _preferencesController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'e.g., "I prefer spicy food and dislike cilantro. I enjoy Mediterranean cuisine."',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Spacer(),
                  // NEW: A row with two distinct buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: _runAiReview,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('AI Review'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _saveProfile,
                        icon: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save),
                        label: const Text('Save'),
                      ),
                    ],
                  )
                ],
              ),
            ),
    );
  }
}