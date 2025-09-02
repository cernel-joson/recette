import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/features/shopping_list/presentation/controllers/shopping_list_controller.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  // Manually create and hold the controller instance.
  late final ShoppingListController _controller;

  @override
  void initState() {
    super.initState();
    // Create the controller and start loading data when the widget is mounted.
    _controller = ShoppingListController();
    _controller.loadItems();
  }

  @override
  void dispose() {
    // Ensure the controller is disposed when the widget is removed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provide the existing controller instance to the widget tree.
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<ShoppingListController>(
        builder: (context, controller, child) {
          return Scaffold(
            // The original Scaffold and its contents remain unchanged.
            appBar: AppBar(
              title: const Text('Shopping List'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: 'Clear All Items',
                  onPressed: controller.items.isEmpty
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Clear Shopping List?'),
                              content: const Text(
                                  'Are you sure you want to delete all items?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Clear'),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.red),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await controller.clearList();
                          }
                        },
                ),
              ],
            ),
            body: Column(
              children: [
                _AddItemBar(controller: controller),
                Expanded(
                  child: controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: controller.items.length,
                          itemBuilder: (context, index) {
                            final item = controller.items[index];
                            return CheckboxListTile(
                              value: item.isChecked,
                              onChanged: (_) => controller.toggleItem(item),
                              title: Text(
                                item.name,
                                style: TextStyle(
                                  decoration: item.isChecked
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              secondary: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () => controller.deleteItem(item.id!),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AddItemBar extends StatefulWidget {
  final ShoppingListController controller;
  const _AddItemBar({required this.controller});

  @override
  State<_AddItemBar> createState() => _AddItemBarState();
}

class _AddItemBarState extends State<_AddItemBar> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    widget.controller.addItem(_textController.text);
    _textController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Add a new item...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.add),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}