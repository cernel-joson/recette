import 'package:flutter/foundation.dart';
import 'package:recette/features/shopping_list/data/models/shopping_list_item_model.dart';
import 'package:recette/features/shopping_list/data/repositories/shopping_list_repository.dart';

/// Service for managing the shopping list.
class ShoppingListService {
  final ShoppingListRepository _repository;

  // Public constructor
  ShoppingListService() : _repository = ShoppingListRepository();

  // Constructor for testing
  @visibleForTesting
  ShoppingListService.internal(this._repository);

  Future<List<ShoppingListItem>> getItems() => _repository.items.getAll();

  Future<void> addItem(ShoppingListItem item) => _repository.items.create(item);

  Future<void> updateItem(ShoppingListItem item) => _repository.items.update(item);

  Future<void> deleteItem(int id) => _repository.items.delete(id);

  Future<void> clearList() => _repository.items.clear();
  
  Future<void> batchInsertItems(List<ShoppingListItem> items) => _repository.items.batchInsert(items);
}