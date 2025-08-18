import 'package:recette/core/services/api_helper.dart';
import 'package:recette/core/services/database_helper.dart';
import 'package:recette/features/inventory/data/models/inventory_models.dart';
import 'package:recette/features/dietary_profile/data/services/profile_service.dart'; // Import profile service


class InventoryService {
  final _db = DatabaseHelper.instance;

  // --- NEW: Method to move a batch of items to a new location ---
  Future<void> moveItemsToLocation(List<int> itemIds, int locationId) async {
    if (itemIds.isEmpty) return;
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final itemId in itemIds) {
        await txn.update(
          'inventory',
          {'location_id': locationId},
          where: 'id = ?',
          whereArgs: [itemId],
        );
      }
    });
  }
  
  // --- NEW: Method to get inventory grouped by location ---
  Future<Map<String, List<InventoryItem>>> getGroupedInventory() async {
    final db = await _db.database;

    // 1. Fetch all locations and all items in parallel
    final locationsFuture = getLocations();
    final itemsFuture = db.query('inventory', orderBy: 'name ASC');
    
    final locations = await locationsFuture;
    final itemMaps = await itemsFuture;
    
    final items = List.generate(itemMaps.length, (i) => InventoryItem.fromMap(itemMaps[i]));

    // 2. Create a lookup map for location names
    final locationMap = {for (var loc in locations) loc.id!: loc.name};

    // 3. Group items by location name
    final groupedItems = <String, List<InventoryItem>>{};

    for (final item in items) {
      final locationName = locationMap[item.locationId] ?? 'Uncategorized';
      if (groupedItems.containsKey(locationName)) {
        groupedItems[locationName]!.add(item);
      } else {
        groupedItems[locationName] = [item];
      }
    }

    return groupedItems;
  }

  // --- Item Management ---
  Future<List<InventoryItem>> getInventory() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query('inventory', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => InventoryItem.fromMap(maps[i]));
  }

  Future<void> addItem(InventoryItem item) async {
    final db = await _db.database;
    await db.insert('inventory', item.toMap());
  }

  Future<void> updateItem(InventoryItem item) async {
    final db = await _db.database;
    await db.update('inventory', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteItem(int id) async {
    final db = await _db.database;
    await db.delete('inventory', where: 'id = ?', whereArgs: [id]);
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
        buffer.writeln('- ${quantity} ${unit} ${item.name}'.trim());
      }
    });
    
    return buffer.toString();
  }

  // --- UPDATED: Import logic is now location-aware ---
  Future<void> importInventoryFromText(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Get current locations to provide context to the AI
    final locations = await getLocations();
    final locationNames = locations.map((loc) => loc.name).toList();
    final locationNameMap = {for (var loc in locations) loc.name.toLowerCase(): loc.id};

    // 2. Send the raw text AND location context to the backend for parsing.
    final requestBody = {
      'inventory_import_request': {
        'text': text,
        'locations': locationNames,
      }
    };
    final parsedItems = await ApiHelper.analyzeRaw(requestBody, model: AiModel.flash) as List<dynamic>;

    // 3. Use a transaction to update the local database.
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('inventory');
      for (var itemMap in parsedItems) {
        final locationName = (itemMap['location_name'] as String?)?.toLowerCase();
        final locationId = locationNameMap[locationName];

        final item = InventoryItem(
          name: itemMap['name'] ?? 'Unknown Item',
          quantity: itemMap['quantity'] ?? '',
          unit: itemMap['unit'] ?? '',
          locationId: locationId, // Assign the found location ID
        );
        await txn.insert('inventory', item.toMap());
      }
    });
  }

  // --- Location Management ---
  Future<List<Location>> getLocations() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query('locations', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Location.fromMap(maps[i]));
  }

  Future<void> addLocation(Location location) async {
    final db = await _db.database;
    await db.insert('locations', location.toMap());
  }

  Future<void> updateLocation(Location location) async {
    final db = await _db.database;
    await db.update('locations', location.toMap(), where: 'id = ?', whereArgs: [location.id]);
  }

  Future<void> deleteLocation(int id) async {
    final db = await _db.database;
    await db.delete('locations', where: 'id = ?', whereArgs: [id]);
  }

  // --- Category Management ---
  Future<List<Category>> getCategories() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query('categories', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<void> addCategory(Category category) async {
    final db = await _db.database;
    await db.insert('categories', category.toMap());
  }

  Future<void> updateCategory(Category category) async {
    final db = await _db.database;
    await db.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<void> deleteCategory(int id) async {
    final db = await _db.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
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
    final response = await ApiHelper.analyzeRaw(requestBody);

    // 4. Return the structured result
    if (response is List) {
      // Ensure all items in the list are of the correct type
      return List<Map<String, dynamic>>.from(response.map((item) => Map<String, dynamic>.from(item)));
    }

    return []; // Return an empty list on failure
  }
}