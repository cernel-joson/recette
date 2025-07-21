import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart'; // Import the new share package
import '../helpers/database_helper.dart';
import '../helpers/profile_helper.dart'; // Import profile helper
import '../helpers/api_helper.dart'; // Import api helper for the result class
import '../models/recipe_model.dart';
import '../widgets/recipe_card.dart';
import 'recipe_edit_screen.dart';
import '../helpers/pdf_generator.dart';
import '../helpers/text_formatter.dart'; // Import our new text formatter
import '../services/health_check_service.dart';

// Enum to define the result of the popup menu
enum _MenuAction { share, delete }

/// A screen dedicated to viewing a single recipe and performing actions on it.
class RecipeViewScreen extends StatefulWidget {
  // CORRECTED: The screen now accepts a recipeId.
  final int recipeId;

  const RecipeViewScreen({super.key, required this.recipeId});

  @override
  State<RecipeViewScreen> createState() => _RecipeViewScreenState();
}

class _RecipeViewScreenState extends State<RecipeViewScreen> {
  // The recipe is now nullable and loaded from the database.
  Recipe? _currentRecipe;
  bool _didChange = false; // Flag to track if an edit/delete occurred.
  
  // 1. Instantiate the service
  final HealthCheckService _healthService = HealthCheckService();

  // 2. State variables for loading and results
  bool _isLoadingHealthCheck = true;
  HealthAnalysisResult? _healthAnalysis;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  /// Fetches the recipe from the database using its ID.
  Future<void> _loadRecipe() async {
    final recipe = await DatabaseHelper.instance.getRecipeById(widget.recipeId);
    if (mounted) {
      setState(() {
        _currentRecipe = recipe;
      });
    }
  }


  Future<void> _editRecipe() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeEditScreen(recipe: _currentRecipe),
      ),
    );
    if (result == true) {
      _didChange = true;
      _loadRecipe(); // Reload the recipe from the database to get fresh data.
    }
  }

  Future<void> _deleteRecipe() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe?'),
        content:
            Text('Are you sure you want to delete "${_currentRecipe!.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.delete(_currentRecipe!.id!);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _showShareOptions() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Recipe As...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF Document'),
              onTap: () {
                Navigator.of(context).pop();
                PdfGenerator.generateAndShareRecipe(_currentRecipe!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Plain Text'),
              onTap: () {
                Navigator.of(context).pop();
                final recipeText = TextFormatter.formatRecipe(_currentRecipe!);
                Share.share(recipeText, subject: _currentRecipe!.title);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// NEW: Performs the health check analysis and displays the result.
  Future<void> _performHealthCheck() async {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      debugPrint("--- Load user's profile and perform health check ---");
      // 1. Load the user's profile
      final profileText = await ProfileHelper.loadProfile();
      if (profileText.isEmpty && mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showProfileEmptyWarning();
        return;
      }

      // 2. Call the API
      /* final result = await ApiHelper.getHealthAnalysis(
        profileText: profileText,
        recipe: _currentRecipe!,
      ); */

      debugPrint("--- getHealthAnalysisForRecipe ---");
      final result = await _healthService.getHealthAnalysisForRecipe(_currentRecipe!);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showHealthCheckResult(result);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// NEW: Shows a dialog warning the user to set up their profile first.
  void _showProfileEmptyWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Profile Found'),
        content: const Text('Please set up your dietary profile first to get a health analysis.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// NEW: Shows the result from the AI in a formatted dialog.
  void _showHealthCheckResult(HealthAnalysisResult result) {
    Color ratingColor = Colors.grey;
    if (result.rating == 'GREEN') ratingColor = Colors.green;
    if (result.rating == 'YELLOW') ratingColor = Colors.orange;
    if (result.rating == 'RED') ratingColor = Colors.red;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('Health Check Result: '),
            Text(
              result.rating,
              style: TextStyle(color: ratingColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.summary, style: const TextStyle(fontStyle: FontStyle.italic)),
              const Divider(height: 24),
              const Text('Suggestions:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...result.suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('• $s'),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_didChange);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentRecipe?.title ?? 'Loading...'),
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(_didChange),
          ),
        ),
        body: _currentRecipe == null
            ? const Center(child: CircularProgressIndicator())
            : RecipeCard(recipe: _currentRecipe!),
        bottomNavigationBar: _currentRecipe == null
            ? null
            : BottomAppBar(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // NEW: Health Check Button
                    TextButton.icon(
                      icon: const Icon(Icons.health_and_safety_outlined),
                      label: const Text('Check'),
                      onPressed: _performHealthCheck,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                      onPressed: _editRecipe,
                    ),
                    // The print and more menu are now combined into the popup
                    PopupMenuButton<_MenuAction>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) {
                        if (action == _MenuAction.share) {
                          _showShareOptions();
                        } else if (action == _MenuAction.delete) {
                          _deleteRecipe();
                        }
                      },
                      itemBuilder: (context) => [
                        // Add Print to this menu
                        PopupMenuItem(
                          onTap: () => PdfGenerator.generateAndPrintRecipe(_currentRecipe!),
                          child: const ListTile(
                            leading: Icon(Icons.print_outlined),
                            title: Text('Print'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: _MenuAction.share,
                          child: ListTile(
                            leading: Icon(Icons.share_outlined),
                            title: Text('Share'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: _MenuAction.delete,
                          child: ListTile(
                            leading: Icon(Icons.delete_outline,
                                color: Colors.red),
                            title: Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}