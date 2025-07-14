import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart'; // Import the new share package
import '../helpers/database_helper.dart';
import '../models/recipe_model.dart';
import '../widgets/recipe_card.dart';
import 'recipe_edit_screen.dart';
import '../helpers/pdf_generator.dart';
import '../helpers/text_formatter.dart'; // Import our new text formatter

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
  late Recipe _currentRecipe;

  @override
  void initState() {
    super.initState();
    _currentRecipe = widget.recipe;
  }

  Future<void> _editRecipe() async {
    final updatedRecipe = await Navigator.push<Recipe>(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeEditScreen(recipe: _currentRecipe),
      ),
    );
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
        Navigator.of(context).pop(true);
      }
    }
  }

  /// NEW: Shows a dialog with different sharing options.
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
                PdfGenerator.generateAndShareRecipe(_currentRecipe);
              },
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Plain Text'),
              onTap: () {
                Navigator.of(context).pop();
                final recipeText = TextFormatter.formatRecipe(_currentRecipe);
                Share.share(recipeText, subject: _currentRecipe.title);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRecipe.title),
      ),
      body: RecipeCard(recipe: _currentRecipe),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
              onPressed: _editRecipe,
            ),
            TextButton.icon(
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print'),
              onPressed: () => PdfGenerator.generateAndPrintRecipe(_currentRecipe),
            ),
            PopupMenuButton<_MenuAction>(
              icon: const Icon(Icons.more_vert),
              onSelected: (action) {
                if (action == _MenuAction.share) {
                  // Call our new share options dialog
                  _showShareOptions();
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