// lib/features/inventory/presentation/screens/inventory_screen.dart

import 'package:flutter/material.dart';
import 'package:recette/features/inventory/data/models/inventory_models.dart';
import 'package:recette/features/inventory/data/services/inventory_service.dart';
import 'package:share_plus/share_plus.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  // State now holds the list of items directly, not the Future
  List<InventoryItem>? _items;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshInventory();
  }

  // Renamed to better reflect its action
  Future<void> _refreshInventory() async {
    setState(() { _isLoading = true; });
    final newItems = await _inventoryService.getInventory();
    if (mounted) {
      setState(() {
        _items = newItems;
        _isLoading = false;
      });
    }
  }

  void _exportInventory() async {
    final inventoryText = await _inventoryService.getInventoryAsText();
    Share.share(inventoryText, subject: 'My Kitchen Inventory');
  }

  void _showImportDialog() async {
    final textController = TextEditingController();
    final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Import from Text'),
              content: TextField(
                controller: textController,
                maxLines: 15,
                decoration: const InputDecoration(
                  hintText: 'Paste your inventory list here...',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel')),
                FilledButton(
                  onPressed: () async {
                    if (textController.text.isNotEmpty) {
                      await _inventoryService.importInventoryFromText(textController.text);
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: const Text('Import'),
                ),
              ],
            ));
    
    if (result == true) {
      _refreshInventory();
    }
  }

  void _showItemDialog({InventoryItem? item}) async {
    final nameController = TextEditingController(text: item?.name ?? '');
    final quantityController = TextEditingController(text: item?.quantity ?? '');
    final unitController = TextEditingController(text: item?.unit ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Add Item' : 'Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Item Name')),
            TextField(controller: quantityController, decoration: const InputDecoration(labelText: 'Quantity')),
            TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final newItem = InventoryItem(
                id: item?.id,
                name: nameController.text,
                quantity: quantityController.text,
                unit: unitController.text,
              );
              if (item == null) {
                await _inventoryService.addItem(newItem);
              } else {
                await _inventoryService.updateItem(newItem);
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      // After saving, just refresh the list.
      _refreshInventory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _exportInventory,
            tooltip: 'Export to Text',
          ),
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined),
            onPressed: _showImportDialog,
            tooltip: 'Import from Text',
          ),
        ],
      ),
      // Replaced FutureBuilder with a direct check on the state variables.
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items == null || _items!.isEmpty
              ? const Center(child: Text('Your inventory is empty.'))
              : ListView.builder(
                  itemCount: _items!.length,
                  itemBuilder: (context, index) {
                    final item = _items![index];
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text('${item.quantity ?? ''} ${item.unit ?? ''}'.trim()),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          await _inventoryService.deleteItem(item.id!);
                          _refreshInventory();
                        },
                      ),
                      onTap: () => _showItemDialog(item: item),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showItemDialog,
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }
}