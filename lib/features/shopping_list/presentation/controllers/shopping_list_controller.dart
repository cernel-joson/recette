import 'package:flutter/foundation.dart';
import 'package:recette/features/shopping_list/data/models/shopping_list_item_model.dart';
import 'package:recette/features/shopping_list/data/services/shopping_list_service.dart';

class ShoppingListController with ChangeNotifier {
  final ShoppingListService _shoppingListService;
  List<ShoppingListItem> _items = [];
  bool _isLoading = false;

  ShoppingListController({ShoppingListService? shoppingListService})
      : _shoppingListService = shoppingListService ?? ShoppingListService() {
    loadItems();
  }

  List<ShoppingListItem> get items => _items;
  bool get isLoading => _isLoading;

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();
    _items = await _shoppingListService.getItems();
    _isLoading = false;
    notifyListeners();
  }

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