import 'package:flutter/foundation.dart';
import 'package:recette/core/services/api_helper.dart';
import 'package:recette/core/services/database_helper.dart';
import 'package:recette/features/inventory/data/models/models.dart';
import 'package:recette/features/inventory/data/repositories/repositories.dart';
import 'package:recette/features/dietary_profile/data/services/profile_service.dart'; // Import profile service

class InventoryService {
  final InventoryRepository _repository;

  // Public constructor uses a real repository instance
  InventoryService() : _repository = InventoryRepository();

  // Internal constructor for testing
  @visibleForTesting
  InventoryService.internal(this._repository);

  // --- Item Management ---
  Future<List<InventoryItem>> getInventory() => _repository.items.getAll();

  Future<void> addItem(InventoryItem item) async {
    await _repository.items.create(item);
  }

  Future<void> updateItem(InventoryItem item) async {
    await _repository.items.update(item);
  }

  Future<void> deleteItem(int id) async {
    await _repository.items.delete(id);
  }

  // --- Category Management ---
  Future<List<InventoryCategory>> getCategories() =>
      _repository.categories.getAll();

  Future<void> addCategory(InventoryCategory category) async {
    await _repository.categories.create(category);
  }

  Future<void> updateCategory(InventoryCategory category) async {
    await _repository.categories.update(category);
  }

  Future<void> deleteCategory(int id) async {
    await _repository.categories.delete(id);
  }

  // --- Location Management ---
  Future<List<Location>> getLocations() => _repository.locations.getAll();

  Future<void> addLocation(Location location) async {
    await _repository.locations.create(location);
  }

  Future<void> updateLocation(Location location) async {
    await _repository.locations.update(location);
  }

  Future<void> deleteLocation(int id) async {
    await _repository.locations.delete(id);
  }
  
  // --- RE-IMPLEMENTED: Method to move a batch of items ---
  Future<void> moveItemsToLocation(List<int> itemIds, int locationId) async {
    await _repository.moveItemsToLocation(itemIds, locationId);
  }
  
  // --- RE-IMPLEMENTED: Method to get inventory grouped by location ---
  Future<Map<String, List<InventoryItem>>> getGroupedInventory() async {
    // 1. Fetch all data from the repository in parallel
    final locationsFuture = _repository.locations.getAll();
    final itemsFuture = _repository.items.getAll();

    final locations = await locationsFuture;
    final items = await itemsFuture;

    // Sort items alphabetically by name
    items.sort((a, b) => a.name.compareTo(b.name));

    // 2. Create a lookup map for location names
    final locationMap = {for (var loc in locations) loc.id!: loc.name};

    // 3. Group items by location name (Business Logic)
    final groupedItems = <String, List<InventoryItem>>{};
    for (final item in items) {
      final locationName = locationMap[item.locationId] ?? 'Uncategorized';
      (groupedItems[locationName] ??= []).add(item);
    }

    return groupedItems;
  }

  Future<void> batchInsertCategories(List<InventoryCategory> categories) {
    return _repository.categories.batchInsert(categories);
  }

  Future<void> batchInsertLocations(List<Location> locations) {
    return _repository.locations.batchInsert(locations);
  }

  Future<void> batchInsertItems(List<InventoryItem> inventoryItems) {
    return _repository.items.batchInsert(inventoryItems);
  }

  Future<void> clearAllInventory() async {
    _repository.items.clear();
    _repository.categories.clear();
    _repository.locations.clear();
  }
  
  /// Exports the entire inventory to a simple, formatted text string with location headings.
  Future<String> getInventoryAsText() async {
    final groupedItems = await getGroupedInventory();
    if (groupedItems.isEmpty) {
      return 'Inventory is empty.';
    }
    
    final buffer = StringBuffer();
    
    groupedItems.forEach((location, items) {
      buffer.writeln('\n--- ${location.toUpperCase()} ---');
      for (var item in items) {
        final quantity = item.quantity ?? '';
        final unit = item.unit ?? '';
        buffer.writeln('- $quantity $unit ${item.name}'.trim());
      }
    });
    
    return buffer.toString();
  }

  // --- NEW METHOD FOR MEAL IDEAS ---
  Future<List<Map<String, dynamic>>> getMealIdeas({String userIntent = ''}) async {
    // 1. Gather the context
    final inventoryItems = await getInventory();
    final profile = await ProfileService.loadProfile();

    // Convert inventory items to a simple list of strings for the prompt
    final inventoryList = inventoryItems.map((item) {
      return '${item.quantity ?? ''} ${item.unit ?? ''} ${item.name}'.trim();
    }).toList();

    // 2. Build the request payload
    final requestBody = {
      'meal_suggestion_request': {
        'inventory': inventoryList,
        'dietary_profile': profile.fullProfileText,
        'user_intent': userIntent,
      }
    };

    // 3. Call the API
    final responseBody = await ApiHelper.analyzeRaw(requestBody);
    
    // --- NEW: Extract data from the new response structure ---
    final aiResult = responseBody['result'];
    final promptText = responseBody['prompt_text'];
    
    final response = aiResult;

    // 4. Return the structured result
    if (response is List) {
      // Ensure all items in the list are of the correct type
      return List<Map<String, dynamic>>.from(response.map((item) => Map<String, dynamic>.from(item)));
    }

    return []; // Return an empty list on failure
  }
}