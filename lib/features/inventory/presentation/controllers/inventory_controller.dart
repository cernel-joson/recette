import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/core/jobs/logic/job_manager.dart';
import 'package:recette/core/presentation/controllers/base_list_controller.dart';
import 'package:recette/features/dietary_profile/data/services/profile_service.dart';
import 'package:recette/features/inventory/data/models/models.dart';
import 'package:recette/features/inventory/data/services/inventory_list_service.dart';

class InventoryController extends BaseListController<InventoryItem, Location> {
  InventoryController({InventoryListService? inventoryListService})
      : super(inventoryListService ?? InventoryListService());

  @override
  InventoryItem createItemFromParsed(Map<String, String> parsed, {required int categoryId, int? id}) {
    final rawQuantity = parsed['parsedQuantity'] ?? '';
    final parts = rawQuantity.split(' ');
    final quantity = parts.isNotEmpty ? parts.first : '';
    final unit = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    
    return InventoryItem(
      id: id,
      name: parsed['parsedName'] ?? 'Unknown Item',
      quantity: quantity,
      unit: unit,
      locationId: categoryId,
    );
  }

  @override
  Location createCategory(String name) {
    return Location(name: name);
  }

  /// Displays a dialog to get user intent and submits a meal suggestion job.
  void getMealIdeas(BuildContext context) async {
    final intentController = TextEditingController();
    final jobManager = JobManager.instance; // Access singleton

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
    
    final inventoryList = textController.text;
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
}