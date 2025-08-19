import 'package:flutter/material.dart';
import 'package:recette/features/dietary_profile/data/models/dietary_profile_model.dart';
import 'package:recette/features/dietary_profile/data/services/profile_service.dart';

/// A screen that allows the user to review and accept AI-suggested
/// refinements to their dietary profile.
class ProfileReviewScreen extends StatefulWidget {
  final DietaryProfile originalProfile;
  final ProfileReview review;

  const ProfileReviewScreen({
    super.key,
    required this.originalProfile,
    required this.review,
  });

  @override
  State<ProfileReviewScreen> createState() => _ProfileReviewScreenState();
}

class _ProfileReviewScreenState extends State<ProfileReviewScreen> {
  late final TextEditingController _rulesController;
  late final TextEditingController _preferencesController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the AI's suggestions
    _rulesController = TextEditingController(text: widget.review.suggestedRules);
    _preferencesController = TextEditingController(text: widget.review.suggestedPreferences);
  }

  @override
  void dispose() {
    _rulesController.dispose();
    _preferencesController.dispose();
    super.dispose();
  }

  void _acceptSuggestions() {
    // When the user accepts, we simply pop the screen and return the
    // new profile based on the current text in the controllers.
    final finalProfile = DietaryProfile(
      rules: _rulesController.text,
      preferences: _preferencesController.text,
    );
    Navigator.of(context).pop(finalProfile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review AI Suggestions'),
        automaticallyImplyLeading: false, // Remove back button
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null), // Discard changes
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Accept & Save'),
              onPressed: _acceptSuggestions,
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "The AI has reviewed your profile and suggested the following refinements. You can edit the text below and save the final version.",
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          _buildReviewSection(
            title: 'Suggested Health Rules & Allergies',
            controller: _rulesController,
            originalText: widget.originalProfile.rules,
          ),
          const SizedBox(height: 24),
          _buildReviewSection(
            title: 'Suggested Likes, Dislikes & Preferences',
            controller: _preferencesController,
            originalText: widget.originalProfile.preferences,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection({
    required String title,
    required TextEditingController controller,
    required String originalText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        if (originalText.isNotEmpty) ...[
          const SizedBox(height: 8),
          ExpansionTile(
            title: const Text('Show My Original Text'),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                color: Colors.grey[200],
                child: Text(originalText),
              ),
            ],
          ),
        ],
      ],
    );
  }
}