import 'package:flutter/material.dart';

import '../models/recipe_model.dart';
import 'recipe_edit_screen.dart';
import '../helpers/database_helper.dart';
import '../widgets/recipe_card.dart';

// --- Recipe Library Screen ---
class RecipeLibraryScreen extends StatefulWidget {
  const RecipeLibraryScreen({super.key});

  @override
  State<RecipeLibraryScreen> createState() => _RecipeLibraryScreenState();
}

class _RecipeLibraryScreenState extends State<RecipeLibraryScreen> {
  // Refactored from a FutureBuilder to a stateful list for easier modification.
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  // Load recipes from the database and update the state.
  Future<void> _loadRecipes() async {
    setState(() { _isLoading = true; });
    final recipesFromDb = await DatabaseHelper.instance.getAllRecipes();
    setState(() {
      _recipes = recipesFromDb;
      _isLoading = false;
    });
  }

  // Delete a recipe from the database and the local list.
  void _deleteRecipe(int index) async {
    final recipeToDelete = _recipes[index];
    if (recipeToDelete.id != null) {
      await DatabaseHelper.instance.delete(recipeToDelete.id!);
      setState(() {
        _recipes.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${recipeToDelete.title}" deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipe Library'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipes.isEmpty
              ? const Center(child: Text('Your library is empty. Analyze and save a recipe to add it here.'))
              : ListView.builder(
                  itemCount: _recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _recipes[index];
                    // Wrap the ListTile in a Dismissible widget for swipe-to-delete.
                    return Dismissible(
                      key: Key(recipe.id.toString()),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _deleteRecipe(index);
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        title: Text(recipe.title),
                        subtitle: Text(recipe.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Scaffold(
                              appBar: AppBar(title: Text(recipe.title)),
                              body: RecipeCard(recipe: recipe),
                            )),
                          ).then((_) => _loadRecipes()); // Refresh list when returning.
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RecipeEditScreen()),
          ).then((_) => _loadRecipes());
        },
        icon: const Icon(Icons.add),
        label: const Text("New Recipe"),
      ),
    );
  }
}