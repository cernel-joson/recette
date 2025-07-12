// lib/screens/recipe_edit_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/recipe_model.dart';
import '../helpers/database_helper.dart';

// This screen handles both creating a new recipe and editing an existing one.
class RecipeEditScreen extends StatefulWidget {
  final Recipe? recipe; // If a recipe is passed, we're in "Edit Mode"

  const RecipeEditScreen({super.key, this.recipe});

  @override
  State<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends State<RecipeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _sourceUrlController;
  
  late List<TextEditingController> _ingredientControllers;
  late List<TextEditingController> _instructionControllers;

  bool _isAiLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing recipe data or as empty
    _populateControllers(widget.recipe);

    // If this is a new recipe, automatically show the paste dialog.
    if (widget.recipe == null) {
      // This ensures the dialog shows after the screen is built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPasteTextDialog();
      });
    }
  }

  void _populateControllers(Recipe? recipe) {
    _titleController = TextEditingController(text: recipe?.title ?? '');
    _descriptionController = TextEditingController(text: recipe?.description ?? '');
    _sourceUrlController = TextEditingController(text: recipe?.sourceUrl ?? '');

    // A more robust way to handle ingredients for editing
    _ingredientControllers = recipe?.ingredients.map((i) {
      String text = i.toString();
      if (i.notes.isNotEmpty) {
        text += ' (${i.notes})';
      }
      return TextEditingController(text: text);
    }).toList() ?? [];

    _instructionControllers = recipe?.instructions.map((i) => TextEditingController(text: i)).toList() ?? [];
  }

  @override
  void dispose() {
    // Dispose all controllers to free up resources
    _titleController.dispose();
    _descriptionController.dispose();
    _sourceUrlController.dispose();
    for (var controller in _ingredientControllers) {
      controller.dispose();
    }
    for (var controller in _instructionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _analyzePastedText(String pastedText) async {
    setState(() { _isAiLoading = true; });
    
    // This is the same cloud function URL from the main screen.
    const cloudFunctionUrl = "https://recipe-analyzer-api-1004204297555.us-central1.run.app";

    try {
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36',
        },
        // Send the text instead of a URL
        body: json.encode({'text': pastedText}),
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        // Create a recipe object from the AI response
        final parsedRecipe = Recipe.fromJson(data, _sourceUrlController.text);
        // Use the new recipe data to repopulate the text fields
        setState(() {
          _populateControllers(parsedRecipe);
        });
      } else {
        // Handle error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error analyzing text: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to analyze text: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isAiLoading = false; });
      }
    }
  }

  void _showPasteTextDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Populate from Text'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Paste your unformatted recipe text below and the AI will try to structure it for you.'),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Paste recipe here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  _analyzePastedText(textController.text);
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Analyze Text'),
            ),
          ],
        );
      },
    );
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      // This parsing is still simplistic. For a production app, you'd want
      // separate fields for each part of the ingredient.
      final ingredients = _ingredientControllers.map((c) => Ingredient(quantity: '', unit: '', name: c.text, notes: '')).toList();
      final instructions = _instructionControllers.map((c) => c.text).toList();

      final newRecipe = Recipe(
        id: widget.recipe?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        sourceUrl: _sourceUrlController.text,
        ingredients: ingredients,
        instructions: instructions,
        prepTime: widget.recipe?.prepTime ?? '',
        cookTime: widget.recipe?.cookTime ?? '',
        totalTime: widget.recipe?.totalTime ?? '',
        servings: widget.recipe?.servings ?? '',
      );

      if (widget.recipe == null) {
        await DatabaseHelper.instance.insert(newRecipe);
      } else {
        await DatabaseHelper.instance.update(newRecipe);
      }
      
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null ? 'New Recipe' : 'Edit Recipe'),
        actions: [
          // Show the "repopulate" button only when editing an existing recipe
          if (widget.recipe != null)
            IconButton(
              icon: const Icon(Icons.paste_sharp),
              tooltip: 'Repopulate from Text',
              onPressed: () {
                 showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) => AlertDialog(
                      title: const Text('Confirm Repopulate'),
                      content: const Text('This will replace all current recipe data with the newly analyzed text. Continue?'),
                      actions: <Widget>[
                        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _showPasteTextDialog();
                          },
                          child: const Text('Continue'),
                        ),
                      ],
                    ),
                  );
              },
            ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Recipe',
            onPressed: _saveForm,
          ),
        ],
      ),
      body: _isAiLoading
        ? const Center(child: CircularProgressIndicator(semanticsLabel: 'AI is analyzing...'))
        : Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _sourceUrlController,
                    decoration: const InputDecoration(labelText: 'Source URL', border: OutlineInputBorder()),
                  ),
                  const Divider(height: 32),
                  Text('Ingredients', style: Theme.of(context).textTheme.titleLarge),
                  ..._buildDynamicTextFields(_ingredientControllers, 'Ingredient'),
                  const Divider(height: 32),
                  Text('Instructions', style: Theme.of(context).textTheme.titleLarge),
                  ..._buildDynamicTextFields(_instructionControllers, 'Instruction'),
                ],
              ),
            ),
          ),
    );
  }

  List<Widget> _buildDynamicTextFields(List<TextEditingController> controllers, String hint) {
    List<Widget> fields = [];
    for (int i = 0; i < controllers.length; i++) {
      fields.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controllers[i],
                  decoration: InputDecoration(labelText: '$hint ${i + 1}'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  setState(() {
                    controllers[i].dispose(); // Dispose the controller before removing
                    controllers.removeAt(i);
                  });
                },
              ),
            ],
          ),
        )
      );
    }
    fields.add(
      TextButton.icon(
        icon: const Icon(Icons.add),
        label: Text('Add $hint'),
        onPressed: () {
          setState(() {
            controllers.add(TextEditingController());
          });
        },
      )
    );
    return fields;
  }
}
