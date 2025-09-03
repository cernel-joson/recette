import 'package:recette/core/data/repositories/base_list_repository.dart';
import 'package:recette/core/data/repositories/data_repository.dart';
import 'package:recette/features/inventory/data/models/models.dart';

/// A repository that adapts the inventory data structure to the generic
/// BaseListRepository, allowing it to be used with the BaseListController.
class InventoryListRepository extends BaseListRepository<InventoryItem, Location> {
  InventoryListRepository()
      : super(
          // Maps the generic 'items' to the specific inventory table.
          items: DataRepository<InventoryItem>(
            tableName: 'inventory',
            fromMap: (map) => InventoryItem.fromMap(map),
          ),
          // Maps the generic 'categories' to the locations table, as locations
          // serve as the categories for inventory items.
          categories: DataRepository<Location>(
            tableName: 'locations',
            fromMap: (map) => Location.fromMap(map),
          ),
        );
}