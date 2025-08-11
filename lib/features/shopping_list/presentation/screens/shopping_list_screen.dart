// lib/features/shopping_list/presentation/screens/shopping_list_screen.dart
import 'package:flutter/material.dart';
import 'package:recette/features/shopping_list/shopping_list.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _service = ShoppingListService();
  final _textController = TextEditingController();
  List<ShoppingListItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  Future<void> _refreshList() async {
    setState(() { _isLoading = true; });
    final items = await _service.getItems();
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _addItem() async {
    await _service.addItem(_textController.text);
    _textController.clear();
    _refreshList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return CheckboxListTile(
                        title: Text(item.name, style: TextStyle(decoration: item.isChecked ? TextDecoration.lineThrough : null)),
                        value: item.isChecked,
                        onChanged: (bool? value) {
                          final updatedItem = ShoppingListItem(id: item.id, name: item.name, isChecked: value ?? false);
                          _service.updateItem(updatedItem).then((_) => _refreshList());
                        },
                        secondary: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _service.deleteItem(item.id!).then((_) => _refreshList()),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(labelText: 'Add Item', border: OutlineInputBorder()),
                          onSubmitted: (_) => _addItem(),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.add), onPressed: _addItem),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}