import 'package:recette/core/data/repositories/data_repository.dart';
import 'package:recette/features/shopping_list/data/models/shopping_list_item_model.dart';

/// The single data access point for all shopping list data.
class ShoppingListRepository {
  /// A generic repository specifically for handling ShoppingListItem objects.
  final items = DataRepository<ShoppingListItem>(
    tableName: 'shopping_list_items',
    fromMap: (map) => ShoppingListItem.fromMap(map),
  );
}