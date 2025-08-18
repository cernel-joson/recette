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
  // State now holds the grouped map of items
  Map<String, List<InventoryItem>>? _groupedItems;
  List<Location> _locations = [];
  bool _isLoading = true;

  // --- NEW: State for selection mode ---
  bool _isSelecting = false;
  final Set<int> _selectedItemIds = {};

  @override
  void initState() {
    super.initState();
    _refreshInventory();
  }

  void _exportInventory() async {
    final inventoryText = await _inventoryService.getInventoryAsText();
    Share.share(inventoryText, subject: 'My Kitchen Inventory');
  }

  Future<void> _refreshInventory() async {
    setState(() { _isLoading = true; });
    final newItems = await _inventoryService.getGroupedInventory();
    final newLocations = await _inventoryService.getLocations();
    if (mounted) {
      setState(() {
        _groupedItems = newItems;
        _locations = newLocations;
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(int itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
        if (_selectedItemIds.isEmpty) {
          _isSelecting = false;
        }
      } else {
        _selectedItemIds.add(itemId);
        _isSelecting = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _isSelecting = false;
      _selectedItemIds.clear();
    });
  }

  void _showMoveDialog() async {
    final Location? selectedLocation = await showDialog<Location>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to...'),
        content: DropdownButtonFormField<Location>(
          items: _locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc.name))).toList(),
          onChanged: (Location? value) {
            Navigator.of(context).pop(value);
          },
          decoration: const InputDecoration(labelText: 'Select Location'),
        ),
      ),
    );

    if (selectedLocation != null) {
      await _inventoryService.moveItemsToLocation(_selectedItemIds.toList(), selectedLocation.id!);
      _clearSelection();
      _refreshInventory();
    }
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
    int? selectedLocationId = item?.locationId;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item == null ? 'Add Item' : 'Edit Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Item Name')),
              TextField(controller: quantityController, decoration: const InputDecoration(labelText: 'Quantity')),
              TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit')),
              DropdownButtonFormField<int>(
                value: selectedLocationId,
                items: _locations.map((loc) => DropdownMenuItem(value: loc.id, child: Text(loc.name))).toList(),
                onChanged: (int? value) => selectedLocationId = value,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
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
                  locationId: selectedLocationId,
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
        );
      },
    );

    if (result == true) {
      _refreshInventory();
    }
  }
  
  // --- NEW METHOD TO HANDLE THE "WHAT CAN I MAKE?" FLOW ---
  void _showMealIdeasDialog() async {
    final intentController = TextEditingController();

    // 1. Ask the user for their intent
    final userIntent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("What's the situation?"),
        content: TextField(
          controller: intentController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "e.g., 'I'm tired and need something quick.'",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(intentController.text),
            child: const Text('Get Ideas'),
          ),
        ],
      ),
    );

    if (userIntent == null || !mounted) return; // User cancelled

    // 2. Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 3. Call the service and get the results
      final ideas = await _inventoryService.getMealIdeas(userIntent: userIntent);
      if (mounted) Navigator.of(context).pop(); // Close loading dialog

      // 4. Display the results
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Meal Ideas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ideas.map((idea) => ListTile(
                title: Text(idea['title'] ?? 'No Title'),
                subtitle: Text(idea['description'] ?? 'No Description'),
              )).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ],
        ),
      );

    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelecting
          ? AppBar(
              leading: IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection),
              title: Text('${_selectedItemIds.length} selected'),
              actions: [
                IconButton(icon: const Icon(Icons.drive_file_move), onPressed: _showMoveDialog, tooltip: 'Move Items'),
              ],
            )
          : AppBar(
              title: const Text('My Inventory'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _showItemDialog(),
                  tooltip: 'Add Item',
                ),
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
      // --- UPDATED BODY TO DISPLAY GROUPED LIST ---
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groupedItems == null || _groupedItems!.isEmpty
              ? const Center(child: Text('Your inventory is empty.'))
              : ListView(
                  children: _groupedItems!.entries.map((entry) {
                    final location = entry.key;
                    final items = entry.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0).copyWith(bottom: 8),
                          child: Text(
                            location,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...items.map((item) => ListTile(
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
                            )),
                        const Divider(),
                      ],
                    );
                  }).toList(),
                ),
      // --- NEW FAB ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showMealIdeasDialog,
        tooltip: 'Get Meal Ideas',
        icon: const Icon(Icons.lightbulb_outline),
        label: const Text('What can I make?'),
      ),
    );
  }
}