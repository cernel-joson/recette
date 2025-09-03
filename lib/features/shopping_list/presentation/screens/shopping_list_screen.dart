import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/features/shopping_list/presentation/controllers/shopping_list_controller.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ShoppingListController>(context, listen: false).loadItems();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listController = context.watch<ShoppingListController>();

    if (listController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Visual'),
            Tab(icon: Icon(Icons.article), text: 'Markdown'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
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
            ...items.map((item) => CheckboxListTile(
                  value: item.isChecked,
                  onChanged: (_) => controller.toggleItem(item),
                  title: Text(
                    item.parsedName ?? item.rawText,
                    style: TextStyle(
                      decoration: item.isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                  subtitle: Text(item.parsedQuantity ?? ''),
                  secondary: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => controller.deleteItem(item.id!),
                  ),
                )),
            const Divider(),
          ],
        );
      }).toList(),
    );
  }
}

