import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/features/inventory/data/models/models.dart';
import 'package:recette/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:recette/core/jobs/logic/job_manager.dart';
import 'package:recette/features/dietary_profile/data/services/profile_service.dart';

/// The UI for the inventory screen, now completely rebuilt to support
/// a dual-editor interface with Visual and Markdown tabs.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // The screen is now responsible for triggering the initial data load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryController>(context, listen: false).loadItems();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _getMealIdeas(BuildContext context) async {
    final controller = Provider.of<InventoryController>(context, listen: false);
    final intentController = TextEditingController();
    final jobManager = Provider.of<JobManager>(context, listen: false);

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

    if (userIntent == null || !context.mounted) return;

    // Use the controller's text field, which contains the up-to-date markdown
    final inventoryList = controller.textController.text;
    final profile = await ProfileService.loadProfile();
    final requestPayload = json.encode({
      'inventory': inventoryList,
      'dietary_profile': profile.fullProfileText,
      'user_intent': userIntent,
    });

    await jobManager.submitJob(
      jobType: 'meal_suggestion',
      requestPayload: requestPayload,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating meal idea... Track progress in the Jobs Tray.'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<InventoryController>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Inventory'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Visual'),
            Tab(icon: Icon(Icons.article), text: 'Markdown'),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              onPressed: () async {
                // The save button now only needs to worry about the markdown view
                if (_tabController.index == 1) {
                  await controller.reconcileMarkdownChanges();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inventory saved!'), backgroundColor: Colors.green),
                );
              },
            )
          ],
        ),
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVisualEditor(controller),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: controller.textController,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _getMealIdeas(context),
        tooltip: 'Get Meal Ideas',
        icon: const Icon(Icons.lightbulb_outline),
        label: const Text('What can I make?'),
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
                )),
            const Divider(),
          ],
        );
      }).toList(),
    );
  }
}



/* import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/features/inventory/data/models/models.dart';
import 'package:recette/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:share_plus/share_plus.dart';
import 'package:recette/core/jobs/logic/job_manager.dart';
import 'package:recette/features/dietary_profile/data/services/profile_service.dart';
import 'package:recette/features/inventory/data/services/inventory_service.dart';

// 1. Converted the widget to a StatefulWidget.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // 2. Added the initState method to call loadItems.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryController>(context, listen: false).loadItems();
    });
  }
  
  void _exportInventory(BuildContext context) async {
    final controller = Provider.of<InventoryController>(context, listen: false);
    final inventoryText = await controller.getInventoryAsText();
    Share.share(inventoryText, subject: 'My Kitchen Inventory');
  }

  void _showMoveDialog(BuildContext context) async {
    final controller = Provider.of<InventoryController>(context, listen: false);
    final Location? selectedLocation = await showDialog<Location>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to...'),
        content: DropdownButtonFormField<Location>(
          items: controller.locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc.name))).toList(),
          onChanged: (Location? value) {
            Navigator.of(context).pop(value);
          },
          decoration: const InputDecoration(labelText: 'Select Location'),
        ),
      ),
    );

    if (selectedLocation != null) {
      await controller.moveSelectedItems(selectedLocation.id!);
    }
  }

  void _showImportDialog(BuildContext context) async {
    final textController = TextEditingController();
    final jobManager = Provider.of<JobManager>(context, listen: false);

    await showDialog<bool>(
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
                      final inventoryService = Provider.of<InventoryService>(context, listen: false);
                      final locations = await inventoryService.getLocations();
                      final locationNames = locations.map((loc) => loc.name).toList();

                      final requestPayload = json.encode({
                        'text': textController.text,
                        'locations': locationNames,
                      });

                      await jobManager.submitJob(
                        jobType: 'inventory_import',
                        requestPayload: requestPayload,
                      );

                      if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(
                             content: Text('Inventory import started...'),
                             backgroundColor: Colors.blue,
                           ),
                         );
                      }
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: const Text('Import'),
                ),
              ],
            ));
  }

  void _showItemDialog(BuildContext context, {InventoryItem? item}) async {
    final controller = Provider.of<InventoryController>(context, listen: false);
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
                items: controller.locations.map((loc) => DropdownMenuItem(value: loc.id, child: Text(loc.name))).toList(),
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
                  await controller.addItem(newItem);
                } else {
                  await controller.updateItem(newItem);
                }
                Navigator.of(context).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _getMealIdeas(BuildContext context) async {
    final controller = Provider.of<InventoryController>(context, listen: false);
    final intentController = TextEditingController();
    final jobManager = Provider.of<JobManager>(context, listen: false);

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

    if (userIntent == null || !context.mounted) return;

    final inventoryList = await controller.getInventoryAsText();
    final profile = await ProfileService.loadProfile();
    final requestPayload = json.encode({
      'inventory': inventoryList,
      'dietary_profile': profile.fullProfileText,
      'user_intent': userIntent,
    });

    await jobManager.submitJob(
      jobType: 'meal_suggestion',
      requestPayload: requestPayload,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating meal idea... Track progress in the Jobs Tray.'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<InventoryController>(context);
    return Scaffold(
      appBar: controller.isSelecting
          ? AppBar(
              leading: IconButton(icon: const Icon(Icons.close), onPressed: controller.clearSelection),
              title: Text('${controller.selectedItemIds.length} selected'),
              actions: [
                IconButton(icon: const Icon(Icons.drive_file_move), onPressed: () => _showMoveDialog(context), tooltip: 'Move Items'),
              ],
            )
          : AppBar(
              title: const Text('My Inventory'),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'add') _showItemDialog(context);
                    if (value == 'import') _showImportDialog(context);
                    if (value == 'export') _exportInventory(context);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(value: 'add', child: ListTile(leading: Icon(Icons.add_circle_outline), title: Text('Add Item'))),
                    const PopupMenuItem<String>(value: 'import', child: ListTile(leading: Icon(Icons.download), title: Text('Import from Text'))),
                    const PopupMenuItem<String>(value: 'export', child: ListTile(leading: Icon(Icons.upload_file), title: Text('Export to Text'))),
                  ],
                ),
              ],
            ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.groupedItems.isEmpty
              ? const Center(child: Text('Your inventory is empty.'))
              : ListView(
                  children: controller.groupedItems.entries.map((entry) {
                    final location = entry.key;
                    final items = entry.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0).copyWith(bottom: 8),
                          child: Text(location, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        ...items.map((item) => ListTile(
                              title: Text(item.name),
                              subtitle: Text('${item.quantity ?? ''} ${item.unit ?? ''}'.trim()),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => controller.deleteItem(item.id!),
                              ),
                              onTap: () => _showItemDialog(context, item: item),
                            )),
                        const Divider(),
                      ],
                    );
                  }).toList(),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _getMealIdeas(context),
        tooltip: 'Get Meal Ideas',
        icon: const Icon(Icons.lightbulb_outline),
        label: const Text('What can I make?'),
      ),
    );
  }
} */