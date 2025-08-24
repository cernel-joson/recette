// lib/features/recipes/presentation/screens/recipe_view_screen.dart

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:recette/core/core.dart';
import 'package:recette/features/recipes/recipes.dart';
import 'package:recette/core/presentation/widgets/health_rating_icon.dart';
import 'package:recette/features/recipes/data/services/recipe_analysis_service.dart';
import 'package:recette/features/recipes/presentation/widgets/recipe_analysis_dialog.dart';
import 'package:recette/core/presentation/widgets/jobs_tray_icon.dart';

import 'package:provider/provider.dart';
import 'package:recette/core/jobs/logic/job_manager.dart';

// Enum to define the result of the popup menu
enum _MenuAction { share, delete, createVariation }


// --- THIS IS THE MISSING WIDGET CLASS ---
class RecipeViewScreen extends StatefulWidget {
  final int recipeId;
  const RecipeViewScreen({super.key, required this.recipeId});

  @override
  State<RecipeViewScreen> createState() => _RecipeViewScreenState();
}
// --- END OF MISSING WIDGET CLASS ---

class _RecipeViewScreenState extends State<RecipeViewScreen> {
  Recipe? _currentRecipe;
  Recipe? _parentRecipe;
  List<Recipe> _variations = [];
  bool _didChange = false;

  @override
  void initState() {
    super.initState();
    _loadRecipeData();
  }

  Future<void> _loadRecipeData() async {
    final recipe = await DatabaseHelper.instance.getRecipeById(widget.recipeId);
    if (recipe == null) return;

    Recipe? parent;
    if (recipe.parentRecipeId != null) {
      parent = await DatabaseHelper.instance.getRecipeById(recipe.parentRecipeId!);
    }
    final variations = await DatabaseHelper.instance.getVariationsForRecipe(recipe.id!);

    if (mounted) {
      setState(() {
        _currentRecipe = recipe;
        _parentRecipe = parent;
        _variations = variations;
      });
    }
  }

  // --- REFACTORED ANALYSIS METHOD ---
  Future<void> _runAnalysis() async {
    if (_currentRecipe == null) return;

    final selectedTasks = await showDialog<Set<RecipeAnalysisTask>>(
      context: context,
      builder: (_) => const RecipeAnalysisDialog(),
    );
    if (selectedTasks == null || selectedTasks.isEmpty || !mounted) return;

    final jobManager = Provider.of<JobManager>(context, listen: false);
    final analysisService = RecipeAnalysisService(jobManager);
    
    try {
      await analysisService.runAnalysisTasks(
        recipe: _currentRecipe!,
        tasks: selectedTasks,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analysis started... Track progress in the Jobs Tray.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _createVariation() async {
    final recipeForVariation = _currentRecipe!.copyWith(isVariation: true);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeEditScreen(
          recipe: recipeForVariation,
          parentRecipeId: _currentRecipe!.id,
        ),
      ),
    );
    if (result == true) {
      _didChange = true;
      _loadRecipeData();
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
      _loadRecipeData();
    }
  }

  Future<void> _deleteRecipe() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe?'),
        content: Text('Are you sure you want to delete "${_currentRecipe!.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.delete(_currentRecipe!.id!);
      if (mounted) Navigator.of(context).pop(true);
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

  String _getRatingText(String? rating) {
    switch (rating) {
      case 'SAFE': return 'Safe to Eat Freely';
      case 'CAUTION': return 'Use with Caution & Scrutiny';
      case 'AVOID': return 'Avoid or Use Sparingly';
      default: return 'Tap to see suggestions.';
    }
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
          title: Row(
            children: [
              Expanded(child: Text(_currentRecipe?.title ?? 'Loading...')),
              if (_currentRecipe != null)
                HealthRatingIcon(healthRating: _currentRecipe!.healthRating),
            ],
          ),
          leading: BackButton(onPressed: () => Navigator.of(context).pop(_didChange)),
          actions: [
            const JobsTrayIcon(),
          ],
        ),
        body: _currentRecipe == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  if (_parentRecipe != null)
                    ListTile(
                      leading: const Icon(Icons.arrow_upward),
                      title: Text('Based on: ${_parentRecipe!.title}'),
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => RecipeViewScreen(recipeId: _parentRecipe!.id!))
                      ),
                    ),
                  
                  // --- UI ELEMENTS FROM RECIPECARD ARE NOW DIRECTLY HERE ---
                  Text(_currentRecipe!.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_currentRecipe!.sourceUrl.isNotEmpty && _currentRecipe!.sourceUrl.startsWith('http'))
                    InkWell(
                      onTap: () => launchUrl(Uri.parse(_currentRecipe!.sourceUrl)),
                      child: Text('Source: ${_currentRecipe!.sourceUrl}', style: TextStyle(color: Colors.blue[800], decoration: TextDecoration.underline)),
                    ),
                  const SizedBox(height: 8),
                  if (_currentRecipe!.description.isNotEmpty)
                    Text(_currentRecipe!.description, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[700])),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 24.0, runSpacing: 8.0,
                    children: [
                      if (_currentRecipe!.prepTime.isNotEmpty) InfoChip(icon: Icons.timer_outlined, label: "Prep: ${_currentRecipe!.prepTime}"),
                      if (_currentRecipe!.cookTime.isNotEmpty) InfoChip(icon: Icons.whatshot_outlined, label: "Cook: ${_currentRecipe!.cookTime}"),
                      if (_currentRecipe!.totalTime.isNotEmpty) InfoChip(icon: Icons.access_time, label: "Total: ${_currentRecipe!.totalTime}"),
                      if (_currentRecipe!.servings.isNotEmpty) InfoChip(icon: Icons.people_outline, label: "Serves: ${_currentRecipe!.servings}"),
                      ..._currentRecipe!.otherTimings.map((timing) => InfoChip(icon: Icons.hourglass_empty, label: "${timing.label}: ${timing.duration}")),
                    ],
                  ),
                  if (_currentRecipe!.healthRating != null && _currentRecipe!.healthRating != 'UNRATED')
                    Card(
                      color: Colors.blueGrey[50],
                      elevation: 0,
                      child: ExpansionTile(
                        leading: HealthRatingIcon(healthRating: _currentRecipe!.healthRating),
                        title: Text('Health Analysis', style: Theme.of(context).textTheme.titleMedium),
                        subtitle: Text(_getRatingText(_currentRecipe!.healthRating)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _currentRecipe!.healthSuggestions?.map((s) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text('• $s'))).toList() ?? [],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // --- NEW: Nutritional Info Section ---
                  if (_currentRecipe!.nutritionalInfo != null && _currentRecipe!.nutritionalInfo!.isNotEmpty)
                    Card(
                      color: Colors.teal[50],
                      elevation: 0,
                      child: ExpansionTile(
                        leading: const Icon(Icons.analytics_outlined, color: Colors.teal),
                        title: Text('Nutritional Info (per serving)', style: Theme.of(context).textTheme.titleMedium),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _currentRecipe!.nutritionalInfo!.entries.map((entry) {
                                final key = entry.key.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
                                final value = entry.value;
                                return Text('• $key: $value');
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_currentRecipe!.tags.isNotEmpty) ...[
                    const Divider(height: 32.0),
                    Text("Tags", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0, runSpacing: 4.0,
                      children: _currentRecipe!.tags.map((tag) {
                        return ActionChip(
                          label: Text(tag),
                          onPressed: () { Navigator.of(context).pop('tag:$tag'); },
                        );
                      }).toList(),
                    ),
                  ],
                  const Divider(height: 32.0),
                  Text("Ingredients", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  for (var ingredient in _currentRecipe!.ingredients)
                    Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text("• ${ingredient.toString()}", style: Theme.of(context).textTheme.bodyLarge)),
                  const Divider(height: 32.0),
                  Text("Instructions", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _currentRecipe!.instructions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(_currentRecipe!.instructions[index], style: Theme.of(context).textTheme.bodyLarge),
                      );
                    },
                  ),
                  // --- END OF CONSOLIDATED UI ---

                  if (_variations.isNotEmpty) ...[
                    const Divider(),
                    Padding(padding: const EdgeInsets.all(16.0), child: Text('Your Variations', style: Theme.of(context).textTheme.titleLarge)),
                    ..._variations.map((variation) => ListTile(
                      title: Text(variation.title),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => RecipeViewScreen(recipeId: variation.id!))
                      ).then((_) => _loadRecipeData()),
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
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Analyze'),
                      onPressed: _runAnalysis // Call the new refactored method
                    ),
                    TextButton.icon(icon: const Icon(Icons.edit_outlined), label: const Text('Edit'), onPressed: _editRecipe),
                    PopupMenuButton<_MenuAction>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) {
                        if (action == _MenuAction.share) _showShareOptions();
                        if (action == _MenuAction.delete) _deleteRecipe();
                        if (action == _MenuAction.createVariation) _createVariation();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: _MenuAction.createVariation, child: ListTile(leading: Icon(Icons.add_circle_outline), title: Text('Create Variation'))),
                        PopupMenuItem(onTap: () => PdfGenerator.generateAndPrintRecipe(_currentRecipe!), child: const ListTile(leading: Icon(Icons.print_outlined), title: Text('Print'))),
                        const PopupMenuItem(value: _MenuAction.share, child: ListTile(leading: Icon(Icons.share_outlined), title: Text('Share'))),
                        const PopupMenuItem(value: _MenuAction.delete, child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)))),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}