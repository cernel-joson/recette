import 'package:flutter/material.dart';
import '../services/recipe_parsing_service.dart';
import '../helpers/database_helper.dart';
import '../models/recipe_model.dart';
import '../models/ingredient_model.dart';
import '../models/timing_info_model.dart';
import '../widgets/ingredient_edit_dialog.dart';
import '../widgets/timing_info_edit_dialog.dart'; // Import the new dialog

/// A screen for creating a new recipe or editing an existing one.
class RecipeEditScreen extends StatefulWidget {
  final Recipe? recipe;
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

  // Use controllers for simple text fields
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _prepTimeController;
  late TextEditingController _cookTimeController;
  late TextEditingController _totalTimeController;
  late TextEditingController _servingsController;

  // Manage complex lists directly in the state
  late List<Ingredient> _ingredients;
  late List<String> _instructions;
  late List<TimingInfo> _otherTimings; // New state list
  late String _sourceUrl;

  // New: A flag to track if any changes have been made.
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _populateState(widget.recipe);
    _addListeners(); // New: Add listeners to track changes.

    if (widget.showPasteDialogOnLoad) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showPasteTextDialog());
    }
  }

  /// Populates all state variables from a Recipe object.
  void _populateState(Recipe? recipe) {
    _titleController = TextEditingController(text: recipe?.title ?? '');
    _descriptionController =
        TextEditingController(text: recipe?.description ?? '');
    _prepTimeController = TextEditingController(text: recipe?.prepTime ?? '');
    _cookTimeController = TextEditingController(text: recipe?.cookTime ?? '');
    _totalTimeController = TextEditingController(text: recipe?.totalTime ?? '');
    _servingsController = TextEditingController(text: recipe?.servings ?? '');
    _ingredients = List<Ingredient>.from(recipe?.ingredients ?? []);
    _instructions = List<String>.from(recipe?.instructions ?? []);
    _otherTimings = List<TimingInfo>.from(recipe?.otherTimings ?? []); // Populate new list
    _sourceUrl = recipe?.sourceUrl ?? '';
  }

  /// New: Adds listeners to all controllers to detect changes.
  void _addListeners() {
    _titleController.addListener(_markDirty);
    _descriptionController.addListener(_markDirty);
    _prepTimeController.addListener(_markDirty);
    _cookTimeController.addListener(_markDirty);
    _totalTimeController.addListener(_markDirty);
    _servingsController.addListener(_markDirty);
  }

  /// New: A simple method to set the dirty flag.
  void _markDirty() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _titleController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _totalTimeController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  /// Saves the form data to the database.
  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final newRecipe = Recipe(
        id: widget.recipe?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        prepTime: _prepTimeController.text,
        cookTime: _cookTimeController.text,
        totalTime: _totalTimeController.text,
        servings: _servingsController.text,
        ingredients: _ingredients,
        instructions: _instructions,
        otherTimings: _otherTimings, // Save the new list
        sourceUrl: _sourceUrl,
      );

      if (widget.recipe?.id != null) {
        await DatabaseHelper.instance.update(newRecipe);
      } else {
        await DatabaseHelper.instance.insert(newRecipe);
      }

      if (mounted) Navigator.of(context).pop(newRecipe);
    }
  }

  // --- List Management Methods (now with _markDirty calls) ---

  Future<void> _editIngredient(int index) async {
    final updatedIngredient = await showDialog<Ingredient>(
      context: context,
      builder: (context) =>
          IngredientEditDialog(ingredient: _ingredients[index]),
    );
    if (updatedIngredient != null && updatedIngredient != _ingredients[index]) {
      setState(() {
        _ingredients[index] = updatedIngredient;
        _markDirty();
      });
    }
  }

  Future<void> _addIngredient() async {
    final newIngredient = await showDialog<Ingredient>(
      context: context,
      builder: (context) => const IngredientEditDialog(),
    );
    if (newIngredient != null) {
      setState(() {
        _ingredients.add(newIngredient);
        _markDirty();
      });
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
      _markDirty();
    });
  }

  Future<void> _editInstruction(int index) async {
    final controller = TextEditingController(text: _instructions[index]);
    final updatedInstruction = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Step ${index + 1}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updatedInstruction != null && updatedInstruction != _instructions[index]) {
      setState(() {
        _instructions[index] = updatedInstruction;
        _markDirty();
      });
    }
  }

  void _addInstruction() {
    setState(() {
      _instructions.add('');
      _markDirty();
    });
    _editInstruction(_instructions.length - 1);
  }

  void _removeInstruction(int index) {
    setState(() {
      _instructions.removeAt(index);
      _markDirty();
    });
  }

  Future<void> _editOtherTiming(int index) async {
    final updatedTiming = await showDialog<TimingInfo>(
      context: context,
      builder: (context) => TimingInfoEditDialog(timingInfo: _otherTimings[index]),
    );
    if (updatedTiming != null && updatedTiming != _otherTimings[index]) {
      setState(() {
        _otherTimings[index] = updatedTiming;
        _markDirty();
      });
    }
  }

  Future<void> _addOtherTiming() async {
    final newTiming = await showDialog<TimingInfo>(
      context: context,
      builder: (context) => const TimingInfoEditDialog(),
    );
    if (newTiming != null) {
      setState(() {
        _otherTimings.add(newTiming);
        _markDirty();
      });
    }
  }

  void _removeOtherTiming(int index) {
    setState(() {
      _otherTimings.removeAt(index);
      _markDirty();
    });
  }

  // --- AI Population logic ---
  void _showPasteTextDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              Navigator.of(context).pop();
              _analyzePastedText(textController.text);
            },
            child: const Text('Analyze'),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzePastedText(String text) async {
    if (text.isEmpty) return;
    try {
      final recipe = await RecipeParsingService.analyzeText(text);
      setState(() {
        _populateState(recipe); // Repopulate all fields with AI data
      });
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing text: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// New: Shows the confirmation dialog when trying to navigate with unsaved changes.
  Future<bool> _showUnsavedChangesDialog() async {
    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Don't discard
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Discard
            child: const Text('Discard'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
    // Return true if the user chose to discard, false otherwise.
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // New: Wrap the Scaffold in a PopScope to intercept back navigation.
    return PopScope(
      // canPop is false if there are unsaved changes, preventing immediate navigation.
      canPop: !_isDirty,
      // onPopInvoked is called when a pop is attempted and canPop is false.
      onPopInvoked: (didPop) async {
        if (didPop) return; // If already popped, do nothing.
        final shouldPop = await _showUnsavedChangesDialog();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.recipe == null ? 'New Recipe' : 'Edit Recipe'),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.paste_sharp),
                label: const Text('Repopulate'),
                onPressed: _showPasteTextDialog,
              ),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                onPressed: _saveForm,
              ),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ... (The rest of the form UI remains the same) ...
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                          controller: _prepTimeController,
                          decoration:
                              const InputDecoration(labelText: 'Prep Time'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextFormField(
                          controller: _cookTimeController,
                          decoration:
                              const InputDecoration(labelText: 'Cook Time'))),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                          controller: _totalTimeController,
                          decoration:
                              const InputDecoration(labelText: 'Total Time'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextFormField(
                          controller: _servingsController,
                          decoration:
                              const InputDecoration(labelText: 'Servings'))),
                ],
              ),
              const SizedBox(height: 24),
              _buildOtherTimingsList(),
              const SizedBox(height: 24),
              _buildIngredientList(),
              const SizedBox(height: 24),
              _buildInstructionList(),
            ],
          ),
        ),
      ),
    );
  }

  // --- New Builder for Other Timings ---
  Widget _buildOtherTimingsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Other Timings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _otherTimings.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(_otherTimings[index].toString()),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () => _removeOtherTiming(index),
              ),
              onTap: () => _editOtherTiming(index),
            );
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Timing'),
          onPressed: _addOtherTiming,
        ),
      ],
    );
  }

  Widget _buildIngredientList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ingredients', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _ingredients.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(_ingredients[index].toString()),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.red),
                onPressed: () => _removeIngredient(index),
              ),
              onTap: () => _editIngredient(index),
            );
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Ingredient'),
          onPressed: _addIngredient,
        ),
      ],
    );
  }

  Widget _buildInstructionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Instructions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _instructions.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Text('${index + 1}.'),
              title: Text(_instructions[index]),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () => _removeInstruction(index),
              ),
              onTap: () => _editInstruction(index),
            );
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Instruction'),
          onPressed: _addInstruction,
        ),
      ],
    );
  }
}