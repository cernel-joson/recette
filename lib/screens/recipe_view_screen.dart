import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart'; // Import the new share package
import '../helpers/database_helper.dart';
import '../models/recipe_model.dart';
import '../widgets/recipe_card.dart';
import 'recipe_edit_screen.dart';
import '../helpers/pdf_generator.dart';
import '../helpers/text_formatter.dart'; // Import our new text formatter
import '../services/health_check_service.dart';

// Enum to define the result of the popup menu
enum _MenuAction { share, delete, createVariation }

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
  Recipe? _parentRecipe;
  List<Recipe> _variations = [];
  bool _didChange = false; // Flag to track if an edit/delete occurred.
  
  // 1. Instantiate the service
  final HealthCheckService _healthService = HealthCheckService();

  // 2. State variables for loading and results
  bool _isLoadingHealthCheck = true;
  HealthAnalysisResult? _healthAnalysis;

  @override
  void initState() {
    super.initState();
    _loadRecipeData();
  }

  /// --- NEW: Consolidated data loading method ---
  Future<void> _loadRecipeData() async {
    final recipe = await DatabaseHelper.instance.getRecipeById(widget.recipeId);
    if (recipe == null) return;

    // Fetch parent if it exists
    Recipe? parent;
    if (recipe.parentRecipeId != null) {
      parent = await DatabaseHelper.instance.getRecipeById(recipe.parentRecipeId!);
    }

    // Fetch variations
    final variations = await DatabaseHelper.instance.getVariationsForRecipe(recipe.id!);
    
    if (mounted) {
      setState(() {
        _currentRecipe = recipe;
        _parentRecipe = parent;
        _variations = variations;
      });
    }
  }

  /// --- UPDATED: Method to create a variation ---
  Future<void> _createVariation() async {
    // By calling copyWith and setting isVariation to true, we create a new,
    // unsaved Recipe object with a null ID and the parentRecipeId set correctly.
    final recipeForVariation = _currentRecipe!.copyWith(parentRecipeId: _currentRecipe!.id, isVariation: true);

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeEditScreen(
          recipe: recipeForVariation,
          // --- THIS IS THE FIX ---
          // We explicitly pass the ID of the current recipe as the
          // parent ID for the new variation.
          parentRecipeId: _currentRecipe!.id,
        ),
      ),
    );
    if (result == true) {
      _didChange = true;
      _loadRecipeData(); // Reload all data to show the new variation
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
      _loadRecipeData(); // Reload the recipe from the database to get fresh data.
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
      final result = await _healthService.getHealthAnalysisForRecipe(_currentRecipe!);
      
      // --- THIS IS THE FIX ---
      // After the service updates the database, we must reload the local recipe
      // object to get the fresh data, including the new fingerprints and ratings.
      await _loadRecipeData();
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        if (result.rating == 'UNRATED') { // A clear signal from the service
          _showProfileEmptyWarning();
        } else {
          _showHealthCheckResult(result);
        }
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
    String ratingCircle = "⚪";
    
    if (result.rating == 'GREEN') ratingColor = Colors.green;
    if (result.rating == 'YELLOW') ratingColor = Colors.orange;
    if (result.rating == 'RED') ratingColor = Colors.red;

    if (result.rating == 'GREEN') ratingCircle = "🟢";
    if (result.rating == 'YELLOW') ratingCircle = "🟡";
    if (result.rating == 'RED') ratingCircle = "🔴";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('Health Check Result: '),
            Text(
              ratingCircle,
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
            // --- NEW: Use a ListView to show lineage info + recipe card ---
            : ListView(
                children: [
                  // --- Parent Recipe Link ---
                  if (_parentRecipe != null)
                    ListTile(
                      leading: const Icon(Icons.arrow_upward),
                      title: Text('Based on: ${_parentRecipe!.title}'),
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => RecipeViewScreen(recipeId: _parentRecipe!.id!))
                      ),
                    ),
                  
                  // --- The Main Recipe Card ---
                  RecipeCard(recipe: _currentRecipe!),

                  // --- Variations List ---
                  if (_variations.isNotEmpty) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Your Variations', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    ..._variations.map((variation) => ListTile(
                      title: Text(variation.title),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => RecipeViewScreen(recipeId: variation.id!))
                      ).then((_) => _loadRecipeData()), // Refresh when returning
                    )),
                  ]
                ],
              ),
        bottomNavigationBar: _currentRecipe == null
            ? null
            : BottomAppBar(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
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
                    PopupMenuButton<_MenuAction>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) {
                        if (action == _MenuAction.share) _showShareOptions();
                        if (action == _MenuAction.delete) _deleteRecipe();
                        if (action == _MenuAction.createVariation) _createVariation();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: _MenuAction.createVariation,
                          child: ListTile(
                            leading: Icon(Icons.add_circle_outline),
                            title: Text('Create Variation'),
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () => PdfGenerator.generateAndPrintRecipe(_currentRecipe!),
                          child: const ListTile(
                            leading: Icon(Icons.print_outlined),
                            title: Text('Print'),
                          ),
                        ),
                        // ... (share and delete menu items are the same) ...
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