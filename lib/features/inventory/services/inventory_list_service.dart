import 'package:recette/core/services/base_list_service.dart';
import 'package:recette/features/inventory/data/models/models.dart';
import 'package:recette/features/inventory/data/repositories/inventory_list_repository.dart';

/// A service that adapts the inventory feature to the generic BaseListService,
/// enabling the use of the dual-editor Markdown functionality.
class InventoryListService extends BaseListService<InventoryItem, Location> {
  InventoryListService({InventoryListRepository? repository})
      : super(repository ?? InventoryListRepository());
}