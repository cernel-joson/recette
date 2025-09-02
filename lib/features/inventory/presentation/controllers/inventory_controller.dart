import 'package:flutter/foundation.dart';
import 'package:recette/core/presentation/controllers/base_controller.dart';
import 'package:recette/features/inventory/data/models/models.dart';
import 'package:recette/features/inventory/data/services/inventory_service.dart';

class InventoryController extends BaseController<InventoryItem> {
  final InventoryService _inventoryService;

  // State specific to the inventory screen
  Map<String, List<InventoryItem>> _groupedItems = {};
  List<Location> _locations = [];
  bool _isSelecting = false;
  final Set<int> _selectedItemIds = {};

  InventoryController({InventoryService? inventoryService})
      : _inventoryService = inventoryService ?? InventoryService();

  // Public getters for the UI
  Map<String, List<InventoryItem>> get groupedItems => _groupedItems;
  List<Location> get locations => _locations;
  bool get isSelecting => _isSelecting;
  Set<int> get selectedItemIds => _selectedItemIds;

  @override
  Future<List<InventoryItem>> fetchItems() async {
    // This is the primary data loading method. We also fetch related data here.
    final groupedItemsFuture = _inventoryService.getGroupedInventory();
    final locationsFuture = _inventoryService.getLocations();
    final inventoryItemsFuture = _inventoryService.getInventory();

    // Await all futures in parallel
    final results = await Future.wait([
      groupedItemsFuture,
      locationsFuture,
      inventoryItemsFuture,
    ]);

    // Update state from the results
    _groupedItems = results[0] as Map<String, List<InventoryItem>>;
    _locations = results[1] as List<Location>;
    
    // Return the primary list of items to the BaseController
    return results[2] as List<InventoryItem>;
  }

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
}