import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'recipe_view_screen.dart'; // Import the new view screen
import 'package:intelligent_nutrition_app/features/recipes/presentation/controllers/controllers.dart';
import 'package:intelligent_nutrition_app/features/recipes/data/services/services.dart';
import 'package:intelligent_nutrition_app/features/recipes/presentation/utils/dialog_utils.dart';

class RecipeLibraryScreen extends StatelessWidget {
  const RecipeLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Create the provider at the top level of the screen.
    return ChangeNotifierProvider(
      create: (_) => RecipeLibraryController(),
      // 2. The actual UI is now built by a child widget that has
      //    access to the provider.
      child: const _RecipeLibraryView(),
    );
  }
}

// --- UPDATED: Converted to a StatefulWidget to manage the TextEditingController ---
class _RecipeLibraryView extends StatefulWidget {
  const _RecipeLibraryView();

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

  @override
  Widget build(BuildContext context) {
    // Get the controller once to use in callbacks.
    final controller = Provider.of<RecipeLibraryController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipe Library'),
        actions: [
          // Import/Export buttons remain the same...
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
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    controller.search(''); // Clear the search results
                  },
                ),
              ),
              onSubmitted: (query) => controller.search(query),
            ),
          ),
        ),
      ),
      body: Consumer<RecipeLibraryController>(
        builder: (context, controller, child) {
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
                  title: Text(recipe.title),
                  subtitle: Text(
                    recipe.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    // CORRECTED: Pass the recipe.id! to the RecipeViewScreen's recipeId parameter.
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeViewScreen(recipeId: recipe.id!),
                      ),
                    );
                    // If the view screen returns true, it means a change (edit or delete) occurred.
                    if (result == true) {
                      // After returning, tell the controller to refresh the data.
                      // We use the Consumer's context here.
                      Provider.of<RecipeLibraryController>(context, listen: false).loadInitialRecipes();
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
}