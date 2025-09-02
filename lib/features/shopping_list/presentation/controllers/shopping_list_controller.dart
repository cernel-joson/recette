import 'package:recette/core/presentation/controllers/base_controller.dart'; // IMPORT base controller
import 'package:recette/features/shopping_list/data/models/shopping_list_item_model.dart';
import 'package:recette/features/shopping_list/data/services/shopping_list_service.dart';

// --- UPDATED: Extend BaseController<ShoppingListItem> ---
class ShoppingListController extends BaseController<ShoppingListItem> {
  final ShoppingListService _shoppingListService;

  // --- REMOVED: Redundant properties handled by the base class ---
  // List<ShoppingListItem> _items = [];
  // bool _isLoading = false;

  ShoppingListController({ShoppingListService? shoppingListService})
      : _shoppingListService = shoppingListService ?? ShoppingListService();
      // BaseController's constructor automatically calls loadItems()

  // --- REMOVED: Redundant `items` and `isLoading` getters ---

  // --- REMOVED: `loadItems` is now handled by the base class ---

  // --- NEW: Implement the required abstract method ---
  @override
  Future<List<ShoppingListItem>> fetchItems() {
    // Tell the base controller how to fetch the data.
    return _shoppingListService.getItems();
  }

  // --- RETAINED: These methods contain specific business logic ---
  Future<void> addItem(String name) async {
    if (name.trim().isEmpty) return;
    final newItem = ShoppingListItem(name: name.trim());
    await _shoppingListService.addItem(newItem);
    await loadItems(); // Reload the list to show the new item
  }

  Future<void> toggleItem(ShoppingListItem item) async {
    final updatedItem = item.copyWith(isChecked: !item.isChecked);
    await _shoppingListService.updateItem(updatedItem);
    await loadItems(); // Reload
  }

  Future<void> deleteItem(int id) async {
    await _shoppingListService.deleteItem(id);
    await loadItems(); // Reload
  }

  Future<void> clearList() async {
    await _shoppingListService.clearList();
    await loadItems(); // Reload
  }
}