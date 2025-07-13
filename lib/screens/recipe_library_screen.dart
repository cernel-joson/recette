// lib/screens/recipe_library_screen.dart

import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/recipe_model.dart';
import '../widgets/recipe_card.dart';
import 'recipe_edit_screen.dart';

/// A screen that displays a list of all recipes saved in the local database.
class RecipeLibraryScreen extends StatefulWidget {
  const RecipeLibraryScreen({super.key});

  @override
  State<RecipeLibraryScreen> createState() => _RecipeLibraryScreenState();
}

class _RecipeLibraryScreenState extends State<RecipeLibraryScreen> {
  // A state variable to hold the list of recipes.
  // It's nullable: null means "loading", an empty list means "no data".
  List<Recipe>? _recipes;

  @override
  void initState() {
    super.initState();
    // Load recipes only once when the widget is first created.
    _loadRecipes();
  }

  /// Fetches all recipes from the database and updates the state.
  Future<void> _loadRecipes() async {
    final recipes = await DatabaseHelper.instance.getAllRecipes();
    // Check if the widget is still in the tree before calling setState.
    if (mounted) {
      setState(() {
        _recipes = recipes;
      });
    }
  }

  /// Deletes a recipe from the database and refreshes the list.
  Future<void> _deleteRecipe(int id) async {
    await DatabaseHelper.instance.delete(id);
    _loadRecipes();
  }

  /// Shows a modal bottom sheet with options for adding a new recipe.
  void _showAddRecipeMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Import from Web (URL)'),
                onTap: () {
                  Navigator.pop(context); // Close the sheet
                  // TODO: Implement URL import dialog
                  debugPrint("Import from URL tapped");
                },
              ),
              ListTile(
                leading: const Icon(Icons.paste),
                title: const Text('Paste Recipe Text'),
                onTap: () {
                  Navigator.pop(context); // Close the sheet
                  // TODO: Navigate to edit screen and trigger text paste dialog
                  debugPrint("Paste Text tapped");
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Enter Manually'),
                onTap: () {
                  Navigator.pop(context); // Close the sheet
                  // TODO: Navigate to a blank edit screen
                  debugPrint("Enter Manually tapped");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the main body of the screen based on the state of the recipe list.
  Widget _buildBody() {
    // 1. Show a loading indicator while recipes are being fetched.
    if (_recipes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Show a message if the library is empty.
    if (_recipes!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Your library is empty.\nTap the + button to add a new recipe.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // 3. If we have recipes, display them in a dismissible list.
    return ListView.builder(
      itemCount: _recipes!.length,
      itemBuilder: (context, index) {
        final recipe = _recipes![index];
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
            _deleteRecipe(recipe.id!);
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
              // When a recipe is tapped, navigate to the RecipeCard view.
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: Text(recipe.title)),
                    body: RecipeCard(recipe: recipe),
                  ),
                ),
              );
              // After returning, refresh the library in case of edits/deletions.
              _loadRecipes();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipe Library'),
      ),
      body: _buildBody(),
      // The FloatingActionButton now opens our new "Add Recipe" menu.
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecipeMenu,
        tooltip: 'Add Recipe',
        child: const Icon(Icons.add),
      ),
    );
  }
}