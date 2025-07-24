import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recipe_model.dart';
import '../models/ingredient_model.dart';

/// A dialog for editing the details of a single ingredient.
class IngredientEditDialog extends StatefulWidget {
  /// The ingredient to be edited. If null, a new ingredient is being created.
  final Ingredient? ingredient;

  const IngredientEditDialog({super.key, this.ingredient});

  @override
  State<IngredientEditDialog> createState() => _IngredientEditDialogState();
}

class _IngredientEditDialogState extends State<IngredientEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _nameController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.ingredient?.quantity ?? '');
    _unitController = TextEditingController(text: widget.ingredient?.unit ?? '');
    _nameController = TextEditingController(text: widget.ingredient?.name ?? '');
    _notesController = TextEditingController(text: widget.ingredient?.notes ?? '');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final updatedIngredient = Ingredient(
        quantity: _quantityController.text,
        unit: _unitController.text,
        name: _nameController.text,
        notes: _notesController.text,
      );
      // Pop the dialog and return the updated ingredient.
      Navigator.of(context).pop(updatedIngredient);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ingredient == null ? 'Add Ingredient' : 'Edit Ingredient'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _quantityController,
                // Use a keyboard that allows decimal points.
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                // Use a regular expression to allow digits, '.', and '/'.
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9./]')),
                ],
                decoration: const InputDecoration(labelText: 'Quantity (e.g., 1, 1/2, 0.5)'),
              ),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(labelText: 'Unit (e.g., cup, tbsp)'),
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (e.g., finely chopped)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}