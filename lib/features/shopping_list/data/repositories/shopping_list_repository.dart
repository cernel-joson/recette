import 'package:recette/core/data/repositories/data_repository.dart';
import 'package:recette/features/shopping_list/data/models/models.dart';

/// The single data access point for all inventory-related data.
/// It creates and holds instances of the generic DataRepository for each table.
class ShoppingListRepository {
  /// A generic repository specifically for handling InventoryItem objects.
  final items = DataRepository<ShoppingListItem>(
    tableName: 'inventory',
    fromMap: (map) => ShoppingListItem.fromMap(map),
  );
}