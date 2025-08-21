import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/features/recipes/presentation/screens/recipe_view_screen.dart'; // Import the new view screen
import 'package:recette/features/recipes/presentation/screens/recipe_edit_screen.dart';
import 'package:recette/features/recipes/data/models/models.dart';
import 'package:recette/features/recipes/presentation/controllers/controllers.dart';
import 'package:recette/features/recipes/presentation/utils/dialog_utils.dart';
import 'package:recette/features/recipes/presentation/widgets/widgets.dart';
import 'package:recette/features/recipes/data/services/services.dart';
import 'package:recette/core/presentation/widgets/widgets.dart';
import 'package:recette/features/recipes/presentation/widgets/pending_job_banner.dart';

// --- ADD THIS IMPORT ---
import 'package:recette/core/presentation/widgets/jobs_tray_icon.dart';
import 'package:recette/core/jobs/data/models/job_model.dart';
import 'package:recette/core/jobs/presentation/controllers/job_controller.dart';

class RecipeLibraryScreen extends StatelessWidget {
  const RecipeLibraryScreen({
    super.key,
    this.isSelecting = false, // New parameter to indicate if we're selecting a recipe
  });
  
  final bool isSelecting;

  @override
  Widget build(BuildContext context) {
    // 1. Create the provider at the top level of the screen.
    return ChangeNotifierProvider(
      create: (_) => RecipeLibraryController(),
      // 2. The actual UI is now built by a child widget that has
      //    access to the provider.
      child: _RecipeLibraryView(isSelecting: isSelecting),
    );
  }
}

// --- UPDATED: Converted to a StatefulWidget to manage the TextEditingController ---
class _RecipeLibraryView extends StatefulWidget {
  const _RecipeLibraryView({required this.isSelecting});
  final bool isSelecting;

  @override
  State<_RecipeLibraryView> createState() => _RecipeLibraryViewState();
}

class _RecipeLibraryViewState extends State<_RecipeLibraryView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showFilterPanel(BuildContext context) async {
    // Get the controller once, outside the async gap.
    final controller = Provider.of<RecipeLibraryController>(context, listen: false);

    final String? constructedQuery = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true, // Allows the sheet to be taller
      builder: (_) => const FilterBottomSheet(),
    );

    if (constructedQuery != null) {
      // If the user applied filters, update the search bar and run the search.
      _searchController.text = constructedQuery;
      controller.search(constructedQuery);
    }
  }

  // --- NEW: Helper method for import action ---
  Future<void> _importLibrary(BuildContext context) async {
    final controller = Provider.of<RecipeLibraryController>(context, listen: false);
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import Recipe Library?'),
          content: const Text('This will add recipes from a JSON backup file. Existing recipes will be skipped.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Import')),
          ],
        ),
      );

      if (confirm != true) return;

      final result = await ImportService.importLibrary();
      
      controller.loadInitialRecipes();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.toString()), backgroundColor: Colors.green),
        );
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- NEW: Helper method for export action ---
  Future<void> _exportLibrary(BuildContext context) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Export Recipe Library?'),
          content: const Text('This will generate a JSON backup file of all your recipes.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Export')),
          ],
        ),
      );

      if (confirm == true) {
        await ExportService.exportLibrary();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  void _reviewPendingJob(Job job) {
    // --- THIS IS THE FIX ---
    // The responsePayload from the worker IS the recipe map.
    // We decode it directly instead of looking for a nested 'recipe' key.
    final recipeMap = json.decode(job.responsePayload!) as Map<String, dynamic>;

    // 2. Create a Recipe object from the stored data.
    final recipe = Recipe.fromMap(recipeMap);

    // 3. Navigate to the edit screen, passing the job ID.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecipeEditScreen(
          recipe: recipe,
          sourceJobId: job.id, // Pass the job ID to be archived on save
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the controller once to use in callbacks.
    final controller = Provider.of<RecipeLibraryController>(context, listen: false);

    return Consumer2<RecipeLibraryController, JobController>(
      builder: (context, libraryController, jobController, child) {
        // --- NEW: Find pending recipe jobs ---
        final pendingJobs = jobController.jobs
            .where((job) =>
                job.jobType == 'recipe_analysis' && job.status == JobStatus.complete)
            .toList();
            
        return Scaffold(
          appBar: AppBar(
          // --- CONDITIONAL LEADING WIDGET ---
          leading: controller.navigatedFromRecipeId != null 
            ? BackButton(
                onPressed: () {
                  // 1. Get the ID of the recipe we want to navigate to.
                  final recipeId = controller.navigatedFromRecipeId!;

                  // 2. IMPORTANT: Reset the library's state to the default view.
                  //    This clears the search, clears the navigation origin, and
                  //    prevents the infinite loop.
                  controller.loadInitialRecipes();

                  // 3. Now, from the clean state, navigate to the recipe.
                  //    Because the state is clean, when the user presses back on the
                  //    recipe screen, they will land on the main library view.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeViewScreen(
                        recipeId: recipeId,
                      ),
                    ),
                  );
                },
              )
            : null, // Use the default (e.g., drawer icon or no button)
            title: const Text('My Recipe Library'),
            // --- THIS IS THE REFACTORED ACTIONS SECTION ---
            actions: [
              const JobsTrayIcon(), // Add the new global icon
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'import') {
                    _importLibrary(context);
                  } else if (value == 'export') {
                    _exportLibrary(context);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'import',
                    child: ListTile(
                      leading: Icon(Icons.download),
                      title: Text('Import Library'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'export',
                    child: ListTile(
                      leading: Icon(Icons.upload_file),
                      title: Text('Export Library'),
                    ),
                  ),
                ],
              ),
            ],
            // --- END OF REFACTORED ACTIONS SECTION ---
            // --- NEW: Add a persistent search bar at the bottom of the AppBar ---
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search (e.g., chicken tag:dinner)',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    contentPadding: EdgeInsets.zero,
                    suffixIcon: Row( // Use a Row for multiple icons
                      mainAxisSize: MainAxisSize.min, // Important
                      children: [
                        IconButton(
                          icon: const Icon(Icons.filter_list), // The new filter button
                          tooltip: 'Filters',
                          onPressed: () {
                            // This will open our new filter panel
                            _showFilterPanel(context);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            controller.search('');
                          },
                        ),
                      ],
                    ),
                  ),
                  onSubmitted: (query) => controller.search(query),
                ),
              ),
            ),
          ),
          body: Builder(
            builder: (context) {
              if (libraryController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  // --- NEW: Display a banner for each pending job ---
                  ...pendingJobs.map((job) => PendingJobBanner(
                        job: job,
                        onView: () => _reviewPendingJob(job),
                      )),
                  
                  if (libraryController.recipes.isEmpty && pendingJobs.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text('No recipes found.'),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: controller.recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = controller.recipes[index];
                          return RecipeCard(
                            recipe: recipe,
                            onTap: () async {
                              // The navigation logic remains the same
                              if (widget.isSelecting) {
                                Navigator.of(context).pop(recipe.id);
                                return;
                              }
                              final dynamic result = await Navigator.push<dynamic>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecipeViewScreen(recipeId: recipe.id!),
                                ),
                              );
                              if (result is String) {
                                controller.setNavigationOrigin(recipe.id!);
                                _searchController.text = result;
                                controller.search(result);
                              } else if (result == true) {
                                controller.clearNavigationOrigin();
                                controller.loadInitialRecipes();
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => DialogUtils.showAddRecipeMenu(context),
            tooltip: 'Add Recipe',
            child: const Icon(Icons.add),
          ),
        );
      }
    );
  }
}