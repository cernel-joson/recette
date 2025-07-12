import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../helpers/database_helper.dart';

// --- Recipe Edit Screen ---
class RecipeEditScreen extends StatefulWidget {
  final Recipe? recipe;

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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.recipe?.title ?? '');
    _descriptionController = TextEditingController(text: widget.recipe?.description ?? '');
    _sourceUrlController = TextEditingController(text: widget.recipe?.sourceUrl ?? '');

    _ingredientControllers = widget.recipe?.ingredients.map((i) => TextEditingController(text: i.toString())).toList() ?? [];
    _instructionControllers = widget.recipe?.instructions.map((i) => TextEditingController(text: i)).toList() ?? [];
  }

  @override
  void dispose() {
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

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
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
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveForm,
          )
        ],
      ),
      body: Form(
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