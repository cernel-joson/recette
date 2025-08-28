import 'package:recette/core/data/repositories/data_repository.dart';
import 'package:recette/core/services/database_helper.dart';
import 'package:recette/features/inventory/data/models/models.dart';

/// The single data access point for all inventory-related data.
/// It creates and holds instances of the generic DataRepository for each table.
class InventoryRepository {
  /// A generic repository specifically for handling InventoryItem objects.
  final items = DataRepository<InventoryItem>(
    tableName: 'inventory',
    fromMap: (map) => InventoryItem.fromMap(map),
  );

  /// A generic repository specifically for handling InventoryCategory objects.
  final categories = DataRepository<InventoryCategory>(
    tableName: 'categories',
    fromMap: (map) => InventoryCategory.fromMap(map),
  );

  /// A generic repository specifically for handling Location objects.
  final locations = DataRepository<Location>(
    tableName: 'locations',
    fromMap: (map) => Location.fromMap(map),
  );

  /// --- NEW: Custom method for batch-updating item locations ---
  /// This is a custom query that doesn't fit the generic repository pattern.
  Future<void> moveItemsToLocation(List<int> itemIds, int locationId) async {
    if (itemIds.isEmpty) return;
    final db = await DatabaseHelper.instance.database;
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
}