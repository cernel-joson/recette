import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/core/presentation/utils/dialog_utils.dart';
import 'package:recette/features/inventory/presentation/controllers/inventory_controller.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryController>(context, listen: false).loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final invController = context.watch<InventoryController>();

    if (invController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // --- THIS IS THE FIX ---
    // The screen now uses a DefaultTabController to manage the tab state,
    // which allows the MainScreen to know which tab is currently active.
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
                _buildVisualEditor(invController),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: invController.textController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '## Fridge\n- 1 gallon Milk...',
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

  Widget _buildVisualEditor(InventoryController controller) {
    if (controller.groupedItems.isEmpty) {
      return const Center(child: Text('Your inventory is empty.'));
    }
    return ListView(
      children: controller.groupedItems.entries.map((entry) {
        final location = entry.key;
        final items = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0).copyWith(bottom: 8),
              child: Text(
                location.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...items.map((item) => ListTile(
                  title: Text(item.name),
                  subtitle: Text('${item.quantity ?? ''} ${item.unit ?? ''}'.trim()),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => controller.deleteItem(item.id!),
                  ),
                  // Make the list tile tappable to edit the item.
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