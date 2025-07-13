import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/recipe_model.dart';
import '../widgets/recipe_card.dart';
import 'recipe_edit_screen.dart';
import '../helpers/pdf_generator.dart'; // We will use the PDF generator here

// Enum to define the result of the popup menu
enum _MenuAction { share, delete }

/// A screen dedicated to viewing a single recipe and performing actions on it.
class RecipeViewScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeViewScreen({super.key, required this.recipe});

  @override
  State<RecipeViewScreen> createState() => _RecipeViewScreenState();
}

class _RecipeViewScreenState extends State<RecipeViewScreen> {
  // We hold the recipe in the state so it can be updated after editing.
  late Recipe _currentRecipe;

  @override
  void initState() {
    super.initState();
    _currentRecipe = widget.recipe;
  }

  Future<void> _editRecipe() async {
    // Navigate to the edit screen.
    final updatedRecipe = await Navigator.push<Recipe>(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeEditScreen(recipe: _currentRecipe),
      ),
    );

    // If the edit screen returns an updated recipe, refresh the state.
    if (updatedRecipe != null) {
      setState(() {
        _currentRecipe = updatedRecipe;
      });
    }
  }

  Future<void> _deleteRecipe() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe?'),
        content: Text('Are you sure you want to delete "${_currentRecipe.title}"?'),
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
      await DatabaseHelper.instance.delete(_currentRecipe.id!);
      if (mounted) {
        // Pop the screen and return true to signal a deletion occurred.
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRecipe.title),
      ),
      // The body of the screen is our simplified RecipeCard.
      body: RecipeCard(recipe: _currentRecipe),
      // The new BottomAppBar for actions.
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Visible "Edit" button
            TextButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
              onPressed: _editRecipe,
            ),
            // Visible "Print" button
            TextButton.icon(
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print'),
              onPressed: () => PdfGenerator.generateAndPrintRecipe(_currentRecipe),
            ),
            // PopupMenuButton for secondary actions
            PopupMenuButton<_MenuAction>(
              icon: const Icon(Icons.more_vert),
              onSelected: (action) {
                if (action == _MenuAction.share) {
                  PdfGenerator.generateAndShareRecipe(_currentRecipe);
                } else if (action == _MenuAction.delete) {
                  _deleteRecipe();
                }
              },
              itemBuilder: (context) => [
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
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}