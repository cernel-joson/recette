import 'package:recette/core/data/models/list_item_model.dart';
import 'package:recette/core/data/repositories/base_list_repository.dart';

/// An abstract service that defines the contract for managing list-based features.
abstract class BaseListService<T extends ListItem, C extends ListCategory> {
  final BaseListRepository<T, C> repository;

  BaseListService(this.repository);

  Future<Map<C, List<T>>> getGroupedItems() => repository.getGroupedItems();

  Future<List<C>> getAllCategories() => repository.categories.getAll();
  Future<C> addCategory(C category) => repository.categories.create(category);
  // A method to delete a category by its ID.
  Future<int> deleteCategory(int id) => repository.categories.delete(id);

  Future<T> addItem(T item) => repository.items.create(item);
  Future<int> updateItem(T item) => repository.items.update(item);
  Future<int> deleteItem(int id) => repository.items.delete(id);

  Future<void> reconcileItems({
    required List<T> itemsToAdd,
    required List<T> itemsToUpdate,
    required List<int> itemIdsToDelete,
  }) =>
      repository.reconcile(
        itemsToAdd: itemsToAdd,
        itemsToUpdate: itemsToUpdate,
        itemIdsToDelete: itemIdsToDelete,
      );
      
  
  Future<List<T>> getAllItems() => repository.items.getAll();

  Future<void> clearList() async {
    await repository.items.clear();
    await repository.categories.clear();
  }

  Future<void> batchInsert(List<T> items) => repository.items.batchInsert(items);
}