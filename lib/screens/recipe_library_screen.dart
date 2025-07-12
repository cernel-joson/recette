// lib/screens/recipe_library_screen.dart

import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/recipe_model.dart';
import '../widgets/recipe_card.dart';
import 'recipe_edit_screen.dart';

class RecipeLibraryScreen extends StatefulWidget {
  const RecipeLibraryScreen({super.key});

  @override
  State<RecipeLibraryScreen> createState() => _RecipeLibraryScreenState();
}

class _RecipeLibraryScreenState extends State<RecipeLibraryScreen> {
  // Use a nullable list. null means "loading", an empty list means "no data".
  List<Recipe>? _recipes;

  @override
  void initState() {
    super.initState();
    // Load recipes only once when the widget is first created.
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final recipes = await DatabaseHelper.instance.getAllRecipes();
    if (mounted) {
      setState(() {
        _recipes = recipes;
      });
    }
  }

  Future<void> _deleteRecipe(int id) async {
    await DatabaseHelper.instance.delete(id);
    _loadRecipes(); // Refresh the list after deleting.
  }

  Widget _buildBody() {
    // 1. Check if recipes are still loading.
    if (_recipes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Check if the library is empty.
    if (_recipes!.isEmpty) {
      return const Center(
        child: Text(
          'Your library is empty. Analyze and save a recipe to add it here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // 3. If we have recipes, display them in the ListView.
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
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: Text(recipe.title)),
                    body: RecipeCard(recipe: recipe),
                  ),
                ),
              );
              // After returning from viewing a recipe, refresh the library
              // in case it was edited or deleted.
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
      // The body is now built using our stateful logic.
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to the edit screen for a new recipe.
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const RecipeEditScreen()),
          );
          // If the new recipe was saved (result is true), refresh the list.
          if (result == true) {
            _loadRecipes();
          }
        },
        tooltip: 'New Recipe',
        child: const Icon(Icons.add),
      ),
    );
  }
}