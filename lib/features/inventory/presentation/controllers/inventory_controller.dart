import 'package:recette/core/presentation/controllers/base_list_controller.dart';
import 'package:recette/features/inventory/data/models/models.dart';
import 'package:recette/features/inventory/data/services/inventory_list_service.dart';

/// The controller for the inventory screen, now refactored to support
/// dual-mode (visual and markdown) editing.
class InventoryController extends BaseListController<InventoryItem, Location> {
  InventoryController({InventoryListService? inventoryListService})
      : super(inventoryListService ?? InventoryListService());

  @override
  InventoryItem createItemFromParsed(Map<String, String> parsed, {required int categoryId, int? id}) {
    // This logic translates the generic parsed map from the Markdown parser
    // into a specific InventoryItem.
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
    // Provides the base controller with a way to create a Location object
    // when a new '##' heading is detected in the markdown.
    return Location(name: name);
  }

  // NOTE: All previous selection and item movement logic has been removed,
  // as these operations are now implicitly handled by the markdown reconciliation.

  /*
  

  // --- All business logic is now in the controller ---

  void toggleSelection(int itemId) {
    if (_selectedItemIds.contains(itemId)) {
      _selectedItemIds.remove(itemId);
      if (_selectedItemIds.isEmpty) {
        _isSelecting = false;
      }
    } else {
      _selectedItemIds.add(itemId);
      _isSelecting = true;
    }
    notifyListeners();
  }

  void clearSelection() {
    _isSelecting = false;
    _selectedItemIds.clear();
    notifyListeners();
  }

  Future<void> moveSelectedItems(int locationId) async {
    await _inventoryService.moveItemsToLocation(
        _selectedItemIds.toList(), locationId);
    clearSelection();
    await loadItems(); // Reload data from the base controller
  }
  
  Future<void> addItem(InventoryItem item) async {
    await _inventoryService.addItem(item);
    await loadItems();
  }
  
  Future<void> updateItem(InventoryItem item) async {
    await _inventoryService.updateItem(item);
    await loadItems();
  }
  
  Future<void> deleteItem(int id) async {
    await _inventoryService.deleteItem(id);
    await loadItems();
  }
  
  Future<String> getInventoryAsText() {
    return _inventoryService.getInventoryAsText();
  }
  */
}