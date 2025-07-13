// lib/screens/recipe_edit_screen.dart

import 'package:flutter/material.dart';
import '../helpers/api_helper.dart'; // Import the new helper
import '../helpers/database_helper.dart';
import '../models/recipe_model.dart';

/// A screen for creating a new recipe or editing an existing one.
class RecipeEditScreen extends StatefulWidget {
  /// The recipe to be edited. If null, a new recipe is being created.
  final Recipe? recipe;

  /// If true, the "Paste Text" dialog will be shown automatically on load.
  /// This is used when creating a new recipe via the paste text option.
  final bool showPasteDialogOnLoad;

  const RecipeEditScreen({
    super.key,
    this.recipe,
    this.showPasteDialogOnLoad = false,
  });

  @override
  State<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends State<RecipeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late List<TextEditingController> _ingredientControllers;
  late List<TextEditingController> _instructionControllers;
  late String _sourceUrl;

  // The cloud function URL is now managed by ApiHelper.

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      // If we're editing an existing recipe, populate the controllers.
      _populateControllers(widget.recipe!);
    } else {
      // If we're creating a new recipe, initialize with empty controllers.
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _ingredientControllers = [TextEditingController()];
      _instructionControllers = [TextEditingController()];
      _sourceUrl = '';

      // If specified, show the paste dialog automatically after the screen builds.
      if (widget.showPasteDialogOnLoad) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _showPasteTextDialog());
      }
    }
  }

  /// Populates the text controllers with data from an existing Recipe object.
  void _populateControllers(Recipe recipe) {
    _titleController = TextEditingController(text: recipe.title);
    _descriptionController = TextEditingController(text: recipe.description);
    _ingredientControllers = recipe.ingredients
        .map((i) => TextEditingController(text: i.toString()))
        .toList();
    _instructionControllers =
        recipe.instructions.map((i) => TextEditingController(text: i)).toList();
    _sourceUrl = recipe.sourceUrl;
  }

  @override
  void dispose() {
    // Dispose all controllers to free up resources.
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _ingredientControllers) {
      controller.dispose();
    }
    for (var controller in _instructionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Adds a new empty text field to a list of controllers.
  void _addTextField(List<TextEditingController> controllers) {
    setState(() {
      controllers.add(TextEditingController());
    });
  }

  /// Removes a text field from a list of controllers at a given index.
  void _removeTextField(List<TextEditingController> controllers, int index) {
    setState(() {
      controllers[index].dispose();
      controllers.removeAt(index);
    });
  }

  /// Saves the form data to the database, either as a new recipe or an update.
  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final newRecipe = Recipe(
        id: widget.recipe?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        // For simplicity, we are not editing these fields in the UI for now.
        prepTime: widget.recipe?.prepTime ?? '',
        cookTime: widget.recipe?.cookTime ?? '',
        totalTime: widget.recipe?.totalTime ?? '',
        servings: widget.recipe?.servings ?? '',
        // We need to parse the ingredient strings back into Ingredient objects.
        // This is a simplified approach; a more robust solution would have separate fields.
        ingredients: _ingredientControllers
            .map((c) => Ingredient.fromString(c.text))
            .toList(),
        instructions: _instructionControllers.map((c) => c.text).toList(),
        sourceUrl: _sourceUrl,
      );

      if (widget.recipe?.id != null) {
        // Update existing recipe
        await DatabaseHelper.instance.update(newRecipe);
      } else {
        // Insert new recipe
        await DatabaseHelper.instance.insert(newRecipe);
      }

      // Pop the screen and return `true` to indicate a save occurred.
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  /// Shows the dialog for pasting and analyzing unformatted recipe text.
  void _showPasteTextDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Populate from Text'),
          content: TextField(
            controller: textController,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Paste your recipe text here...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                _analyzePastedText(textController.text);
              },
              child: const Text('Analyze'),
            ),
          ],
        );
      },
    );
  }

  /// Analyzes pasted text by calling the centralized ApiHelper.
  Future<void> _analyzePastedText(String text) async {
    if (text.isEmpty) return;

    // Show a loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analyzing text...')),
    );

    try {
      // Call the centralized ApiHelper method.
      final recipe = await ApiHelper.analyzeText(text);
      setState(() {
        _populateControllers(recipe);
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Fields populated successfully!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null ? 'New Recipe' : 'Edit Recipe'),
        actions: [
          // Show the paste/repopulate button in the app bar.
          IconButton(
            icon: const Icon(Icons.paste_sharp),
            tooltip: 'Populate from Text',
            onPressed: () {
              if (widget.recipe != null) {
                // If editing, confirm before overriding data.
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Confirm'),
                    content: const Text(
                        'This will replace all current recipe data. Continue?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel')),
                      ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _showPasteTextDialog();
                          },
                          child: const Text('Continue')),
                    ],
                  ),
                );
              } else {
                _showPasteTextDialog();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveForm,
            tooltip: 'Save Recipe',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildEditableList(
                'Ingredients', _ingredientControllers, _addTextField, _removeTextField),
            const SizedBox(height: 24),
            _buildEditableList(
                'Instructions', _instructionControllers, _addTextField, _removeTextField),
          ],
        ),
      ),
    );
  }

  /// A reusable helper widget to build a list of editable text fields.
  Widget _buildEditableList(
      String title,
      List<TextEditingController> controllers,
      Function(List<TextEditingController>) onAdd,
      Function(List<TextEditingController>, int) onRemove) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controllers.length,
          itemBuilder: (context, index) {
            return Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controllers[index],
                    decoration: InputDecoration(labelText: 'Step ${index + 1}'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => onRemove(controllers, index),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: Text('Add $title'),
          onPressed: () => onAdd(controllers),
        ),
      ],
    );
  }
}