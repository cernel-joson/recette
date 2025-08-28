// lib/features/inventory/presentation/screens/inventory_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/features/inventory/data/models/models.dart';
import 'package:recette/features/inventory/data/services/inventory_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:recette/core/presentation/widgets/jobs_tray_icon.dart';
import 'package:recette/core/jobs/logic/job_manager.dart';
import 'package:recette/core/jobs/presentation/controllers/job_controller.dart';

import 'package:recette/core/jobs/data/models/job_model.dart';
// import 'package:recette/features/inventory/presentation/widgets/meal_ideas_banner.dart';
// import 'package:recette/features/inventory/presentation/screens/meal_ideas_screen.dart';
import 'package:recette/features/dietary_profile/data/services/profile_service.dart';


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
    final jobManager = Provider.of<JobManager>(context, listen: false);

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
                      // Get locations to provide context to the AI
                      final locations = await _inventoryService.getLocations();
                      final locationNames = locations.map((loc) => loc.name).toList();

                      final requestPayload = json.encode({
                        'text': textController.text,
                        'locations': locationNames,
                      });

                      await jobManager.submitJob(
                        jobType: 'inventory_import',
                        requestPayload: requestPayload,
                      );

                      if (mounted) {
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
    
    // No need to refresh here, the job system will handle updates.
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

  // This method is now much simpler. It just submits the job.
  /* void _getMealIdeas() async {
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

    if (userIntent == null || !mounted) return;

    // Gather context and build payload
    final inventoryList = await _inventoryService.getInventoryAsText();
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating meal ideas... Track progress in the Jobs Tray.'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  } */

 // This method now just submits the job and provides immediate feedback.
  void _getMealIdeas() async {
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

    if (userIntent == null || !mounted) return;

    final inventoryList = await _inventoryService.getInventoryAsText();
    final profile = await ProfileService.loadProfile();
    final requestPayload = json.encode({
      'inventory': inventoryList,
      'dietary_profile': profile.fullProfileText,
      'user_intent': userIntent,
    });

    await jobManager.submitJob(
      jobType: 'meal_suggestion', // Use the specific job type
      requestPayload: requestPayload,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating meal idea... Track progress in the Jobs Tray.'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
  
  /* void _viewMealIdeas(Job job) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MealIdeasScreen(job: job)),
    );
  } */

  @override
  Widget build(BuildContext context) {
    // We now need to listen to the JobController to see completed meal suggestion jobs
    return Consumer<JobController>(
      builder: (context, jobController, child) {
        final pendingMealJobs = jobController.jobs.where((job) =>
            job.jobType == 'meal_suggestion' && job.status == JobStatus.complete);
        
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
                const JobsTrayIcon(), // Add the new global icon
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'add') {
                      _showItemDialog();
                    } else if (value == 'import') {
                      _showImportDialog();
                    } else if (value == 'export') {
                      _exportInventory();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'add',
                      child: ListTile(
                        leading: Icon(Icons.add_circle_outline),
                        title: Text('Add Item'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'import',
                      child: ListTile(
                        leading: Icon(Icons.download),
                        title: Text('Import from Text'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'export',
                      child: ListTile(
                        leading: Icon(Icons.upload_file),
                        title: Text('Export to Text'),
                      ),
                    ),
                  ],
                ),
              ],
            ),

          body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groupedItems == null || _groupedItems!.isEmpty
              ? const Center(child: Text('Your inventory is empty.'))

          /*body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column( // Wrap body in a Column to add the banner
                  children: [
                    // --- NEW: Display a banner for each pending job ---
                    ...pendingMealJobs.map((job) => MealIdeasBanner(
                          job: job,
                          onView: () => _viewMealIdeas(job),
                        )),
                    Expanded(
                      child: _groupedItems == null || _groupedItems!.isEmpty
                          ? const Center(child: Text('Your inventory is empty.'))*/
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
                    /*),
                  ],
                ),*/
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _getMealIdeas, // Call the refactored method
            tooltip: 'Get Meal Ideas',
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('What can I make?'),
          ),
        );
      },
    );
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
                const JobsTrayIcon(), // Add the new global icon
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'add') {
                      _showItemDialog();
                    } else if (value == 'import') {
                      _showImportDialog();
                    } else if (value == 'export') {
                      _exportInventory();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'add',
                      child: ListTile(
                        leading: Icon(Icons.add_circle_outline),
                        title: Text('Add Item'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'import',
                      child: ListTile(
                        leading: Icon(Icons.download),
                        title: Text('Import from Text'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'export',
                      child: ListTile(
                        leading: Icon(Icons.upload_file),
                        title: Text('Export to Text'),
                      ),
                    ),
                  ],
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