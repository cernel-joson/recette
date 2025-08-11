import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/features/recipes/presentation/screens/recipe_view_screen.dart'; // Import the new view screen
import 'package:recette/features/recipes/presentation/controllers/controllers.dart';
import 'package:recette/features/recipes/presentation/utils/dialog_utils.dart';
import 'package:recette/features/recipes/presentation/widgets/widgets.dart';
import 'package:recette/features/recipes/data/services/services.dart';
import 'package:recette/core/presentation/widgets/widgets.dart';


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

  @override
  Widget build(BuildContext context) {
    // Get the controller once to use in callbacks.
    final controller = Provider.of<RecipeLibraryController>(context, listen: false);

    return Consumer<RecipeLibraryController>(
      builder: (context, controller, child) {
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
            actions: [
              // --- NEW: Import Button ---
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Import Library',
                onPressed: () async {
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
                    
                    // Refresh the library and show the results
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
                },
              ),
              IconButton(
                icon: const Icon(Icons.upload_file),
                tooltip: 'Export Library',
                onPressed: () async {
                  try {
                    // Show a confirmation before exporting
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Export Recipe Library?'),
                        content: const Text('This will generate a JSON backup file of all your recipes that you can save to your device or a cloud service.'),
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
                    // Show an error if something goes wrong (e.g., library is empty)
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Export failed: ${e.toString()}'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),
            ],
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
              if (controller.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              // --- UPDATED: The list now correctly reflects the controller's state ---
              if (controller.recipes.isEmpty) {
                return const Center(
                  child: Text(
                    'No recipes found.\nTry a different search or add a new recipe.'),
                );
              }
              
              return ListView.builder(
                itemCount: controller.recipes.length,
                itemBuilder: (context, index) {
                  final recipe = controller.recipes[index];
                  return Dismissible(
                    key: Key(recipe.id.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      controller.deleteRecipe(recipe.id!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('"${recipe.title}" deleted')),
                      );
                    },
                    child: ListTile(
                      leading: HealthRatingIcon(healthRating: recipe.healthRating), // NEW
                      title: Text(recipe.title),
                      subtitle: Text(
                        recipe.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () async {
                        if (widget.isSelecting) {
                          Navigator.of(context).pop(recipe.id);
                          return;
                        }
                        // We now expect a dynamic result, which could be a bool or a String.
                        final dynamic result = await Navigator.push<dynamic>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeViewScreen(recipeId: recipe.id!),
                          ),
                        );
                        // If the view screen returns true, it means a change (edit or delete) occurred.
                        // --- THIS IS THE CHANGE ---
                        if (result is String) {
                          // --- THIS IS THE KEY ---
                          // When a tag search is triggered, we record where we came from.
                          controller.setNavigationOrigin(recipe.id!); // Assuming a new method in the controller

                          // If the result is a string, it's our search query from the tag.
                          // Update the search bar text and perform the search.
                          _searchController.text = result;
                          controller.search(result);
                        } else if (result == true) {
                          // Otherwise, handle the original logic for when a recipe was
                          // edited or deleted.
                          controller.clearNavigationOrigin(); // Clear state on a simple refresh
                          controller.loadInitialRecipes();
                        }
                      },
                    ),
                  );
                },
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