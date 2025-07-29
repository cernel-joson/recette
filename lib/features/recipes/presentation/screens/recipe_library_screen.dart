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

class _RecipeLibraryView extends StatelessWidget {
  const _RecipeLibraryView();
  

  @override
  Widget build(BuildContext context) {
    // Get the controller once to use in the onPressed callbacks.
    final controller = Provider.of<RecipeLibraryController>(context, listen: false);

    // The ChangeNotifierProvider creates the controller and makes it available
    // to all widgets below it in the tree.
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipe Library'),
        // --- NEW: Add an actions list for the export button ---
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
                controller.loadRecipes();
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
      ),
      // The Consumer widget listens for notifications and rebuilds the UI
      body: Consumer<RecipeLibraryController>(
        builder:(context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (controller.recipes == null || controller.recipes!.isEmpty) {
            return const Center(
              child: Text('Your library is empty.\nTap the + button to add a new recipe.'),
            );
          }
          
          // Your existing ListView.builder logic goes here,
          // but it uses the controller's data.
          return ListView.builder(
            itemCount: controller.recipes!.length,
            itemBuilder: (context, index) {
              final recipe = controller.recipes![index];
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
                      Provider.of<RecipeLibraryController>(context, listen: false).loadRecipes();
                    }
                  },
                ),
              );
            },
          );
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => DialogUtils.showAddRecipeMenu(context), // Pass the build context here
        tooltip: 'Add Recipe',
        child: const Icon(Icons.add),
      ),
    );
  }
}


/*class RecipeLibraryScreen extends StatefulWidget {
  const RecipeLibraryScreen({super.key});

  @override
  State<RecipeLibraryScreen> createState() => _RecipeLibraryScreenState();
}

class _RecipeLibraryScreenState extends State<RecipeLibraryScreen> {
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipe Library'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecipeMenu,
        tooltip: 'Add Recipe',
        child: const Icon(Icons.add),
      ),
    );
  }
}*/