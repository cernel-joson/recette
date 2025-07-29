import 'package:flutter/material.dart';
import 'package:intelligent_nutrition_app/features/dietary_profile/data/services/profile_service.dart';
import 'package:intelligent_nutrition_app/features/dietary_profile/data/models/dietary_profile_model.dart';
import 'profile_review_screen.dart'; // Import the new review screen

/// A screen for viewing and editing the user's dietary profile.
class DietaryProfileScreen extends StatefulWidget {
  const DietaryProfileScreen({super.key});

  @override
  State<DietaryProfileScreen> createState() => _DietaryProfileScreenState();
}

class _DietaryProfileScreenState extends State<DietaryProfileScreen> {
  // Use two separate controllers for the text fields
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
    // Load the profile model from the service
    final profile = await ProfileService.loadProfile();
    if (mounted) {
      setState(() {
        // Populate the controllers from the model
        _rulesController.text = profile.rules;
        _preferencesController.text = profile.preferences;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    setState(() { _isSaving = true; });

    final currentProfile = DietaryProfile(
      rules: _rulesController.text,
      preferences: _preferencesController.text,
    );

    if (currentProfile.fullProfileText.isEmpty) {
      await ProfileService.saveProfile(DietaryProfile());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile cleared.')),
        );
        Navigator.of(context).pop();
      }
      setState(() { _isSaving = false; });
      return;
    }

    try {
      // Step 1: Get AI review. This now returns a structured object.
      final review = await ProfileService.reviewProfile(currentProfile);

      // Step 2: Navigate to the new review screen.
      // We await a result, which will be the final, user-approved profile.
      final finalProfile = await Navigator.of(context).push<DietaryProfile>(
        MaterialPageRoute(
          builder: (context) => ProfileReviewScreen(
            originalProfile: currentProfile,
            review: review,
          ),
        ),
      );

      // Step 3: If the user accepted and saved, the result will not be null.
      if (finalProfile != null) {
        await ProfileService.saveProfile(finalProfile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Profile saved successfully!'),
                backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
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
                  const Spacer(), // Pushes the button to the bottom
                  
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: const Text('Review & Save Profile'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}