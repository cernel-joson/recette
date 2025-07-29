import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/ingredient_model.dart';
import 'package:flutter/foundation.dart';

// --- New Helper Function ---
// This function robustly parses a string to a double. It handles whitespace
// and common fraction characters that double.tryParse cannot handle on its own.
double? _parseNumericQuantity(String input) {
  // First, remove any leading/trailing whitespace which causes parsing to fail.
  String processedInput = input.trim();
  debugPrint(processedInput);

  // Replace common single-character fractions with their decimal equivalents.
  processedInput = processedInput.replaceAll('½', '0.5');
  processedInput = processedInput.replaceAll('¼', '0.25');
  processedInput = processedInput.replaceAll('¾', '0.75');
  processedInput = processedInput.replaceAll('⅓', '0.333');
  processedInput = processedInput.replaceAll('⅔', '0.667');
  processedInput = processedInput.replaceAll('⅛', '0.125');

  // After cleaning the string, attempt to parse it.
  return double.tryParse(processedInput);
}

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
        quantityNumeric: _parseNumericQuantity(_quantityController.text),
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
                // The keyboard is now standard text to allow for "a splash", etc.
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(labelText: 'Quantity (e.g., 2, 1/2, a splash)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a quantity';
                  }
                  return null;
                },
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