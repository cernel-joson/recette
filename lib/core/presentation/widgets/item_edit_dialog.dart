import 'package:flutter/material.dart';
import 'package:recette/core/data/models/list_item_model.dart';

/// A generic dialog for adding or editing a ListItem.
class ItemEditDialog extends StatefulWidget {
  final ListItem? item;
  final List<ListCategory> categories;
  final int? initialCategoryId;

  const ItemEditDialog({
    super.key,
    this.item,
    required this.categories,
    this.initialCategoryId,
  });

  @override
  State<ItemEditDialog> createState() => _ItemEditDialogState();
}

class _ItemEditDialogState extends State<ItemEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late int _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.parsedName ?? '');
    _quantityController = TextEditingController(text: widget.item?.parsedQuantity ?? '');
    // --- THIS IS THE FIX ---
    // Safely determine the initial category ID.
    // It prioritizes the item's own category, then the initial one passed in,
    // and finally falls back to the first available category if all else fails.
    _selectedCategoryId = widget.item?.categoryId ??
                          widget.initialCategoryId ??
                          (widget.categories.isNotEmpty ? widget.categories.first.id! : -1);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      // Return a map of the raw data. The controller will handle object creation.
      Navigator.of(context).pop({
        'name': _nameController.text,
        'quantity': _quantityController.text,
        'categoryId': _selectedCategoryId,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If there are no categories, we cannot add an item.
    if (widget.categories.isEmpty) {
       return const AlertDialog(
        title: Text('Error'),
        content: Text('You must have at least one category or location to add an item.'),
      );
    }
    
    return AlertDialog(
      title: Text(widget.item == null ? 'Add Item' : 'Edit Item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Item Name'),
              validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
            ),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity (e.g., 2 lbs, 1 carton)'),
            ),
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              items: widget.categories.map((category) {
                return DropdownMenuItem<int>(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Category'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}