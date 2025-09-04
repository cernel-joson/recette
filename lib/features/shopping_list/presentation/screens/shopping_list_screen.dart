import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/core/presentation/utils/dialog_utils.dart';
import 'package:recette/features/shopping_list/presentation/controllers/shopping_list_controller.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ShoppingListController>(context, listen: false).loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final listController = context.watch<ShoppingListController>();

    if (listController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // --- THIS IS THE FIX ---
    // The screen now uses a DefaultTabController to manage the tab state.
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list_alt), text: 'Visual'),
              Tab(icon: Icon(Icons.article), text: 'Markdown'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildVisualEditor(listController),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: listController.textController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '## Produce\n- 2 Apples...',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualEditor(ShoppingListController controller) {
    if (controller.groupedItems.isEmpty) {
      return const Center(child: Text('Your shopping list is empty.'));
    }
    return ListView(
      children: controller.groupedItems.entries.map((entry) {
        final category = entry.key;
        final items = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0).copyWith(bottom: 8),
              child: Text(
                category.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...items.map((item) => ListTile(
                  // Use a regular ListTile with a Checkbox in the leading slot.
                  leading: Checkbox(
                    value: item.isChecked,
                    onChanged: (_) => controller.toggleItem(item),
                  ),
                  title: Text(
                    item.parsedName ?? item.rawText,
                    style: TextStyle(
                      decoration: item.isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                  subtitle: Text(item.parsedQuantity ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => controller.deleteItem(item.id!),
                  ),
                  // The ListTile's onTap is now free to handle editing.
                  onTap: () => DialogUtils.showItemEditDialog(
                    context: context,
                    controller: controller,
                    item: item,
                  ),
                )),
            const Divider(),
          ],
        );
      }).toList(),
    );
  }
}