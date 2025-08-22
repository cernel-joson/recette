// lib/features/dietary_profile/presentation/screens/dietary_profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/core/jobs/logic/job_manager.dart';
import 'package:recette/features/dietary_profile/data/models/dietary_profile_model.dart';
import 'package:recette/features/dietary_profile/data/services/profile_service.dart';
import 'package:recette/features/dietary_profile/data/utils/profile_parser.dart';
import 'package:recette/core/presentation/widgets/jobs_tray_icon.dart';


class DietaryProfileScreen extends StatefulWidget {
  const DietaryProfileScreen({super.key});

  @override
  State<DietaryProfileScreen> createState() => _DietaryProfileScreenState();
}

class _DietaryProfileScreenState extends State<DietaryProfileScreen> with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;

  // NEW: Add a listener to rebuild the visual tab when the text changes.
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _textController.addListener(() => setState(() {})); // This triggers rebuilds
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; });
    final profile = await ProfileService.loadProfile();
    if (mounted) {
      setState(() {
        _textController.text = profile.markdownText;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() { _isSaving = true; });
    final newProfile = DietaryProfile(markdownText: _textController.text);
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
    final profileText = _textController.text;

    if (profileText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile is empty. Nothing to review.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final requestPayload = json.encode({'profile_text': profileText});

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
    _textController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Parse the markdown text on every build.
    final parsedCategories = ProfileParser.parse(_textController.text);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dietary Profile'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.article), text: 'Markdown'),
            Tab(icon: Icon(Icons.list_alt), text: 'Visual'),
          ],
        ),
        actions: [
          const JobsTrayIcon(), // Add the new global icon
        ]
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
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
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Markdown Editor Tab
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _textController,
                    maxLines: null, // Allows infinite lines
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: '## Sugar\n- Prioritize foods with 0g of added sugar...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                
                // --- NEW: Visual Editor Tab ---
                ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: parsedCategories.length,
                  itemBuilder: (context, index) {
                    final category = parsedCategories[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ExpansionTile(
                        title: Text(category.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        initiallyExpanded: true,
                        children: category.rules.map((rule) {
                          return ListTile(
                            contentPadding: EdgeInsets.only(left: 16.0 + (rule.indentation * 16.0), right: 16.0),
                            title: Text(rule.text),
                            // We will add onTap for editing in the next phase
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}