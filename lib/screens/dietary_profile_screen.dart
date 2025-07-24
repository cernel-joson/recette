import 'package:flutter/material.dart';
import '../services/profile_service.dart';

/// A screen for viewing and editing the user's dietary profile.
class DietaryProfileScreen extends StatefulWidget {
  const DietaryProfileScreen({super.key});

  @override
  State<DietaryProfileScreen> createState() => _DietaryProfileScreenState();
}

class _DietaryProfileScreenState extends State<DietaryProfileScreen> {
  final _controller = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; });
    final profileText = await ProfileService.loadProfile();
    if (mounted) {
      setState(() {
        _controller.text = profileText;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    setState(() { _isSaving = true; });

    final inputText = _controller.text;
    if (inputText.isEmpty) {
      await ProfileService.saveProfile('');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile cleared.')),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    try {
      // Step 1: Get AI review
      final review = await ProfileService.reviewProfile(inputText);

      // Step 2: Show confirmation dialog
      final bool? saveConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Review Your Profile'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Here's a summary of what the AI understood. You can edit your text or save it as is.",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const Divider(height: 24),
                Text(review),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Let Me Edit'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save Anyway'),
            ),
          ],
        ),
      );

      // Step 3: Save if confirmed
      if (saveConfirmed == true) {
        await ProfileService.saveProfile(inputText);
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
    _controller.dispose();
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
                  const Text(
                    'Describe your dietary goals, rules, and preferences in your own words below. The AI will use this information to help you plan meals and analyze recipes.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null, // Allows the text field to expand
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: 'e.g., "I need a heart-healthy diet, low in sodium (under 200mg per serving) and saturated fat. I also dislike cilantro."',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: const Text('Save Profile'),
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