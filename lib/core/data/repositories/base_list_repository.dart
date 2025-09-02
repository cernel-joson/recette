import 'package:recette/core/data/models/list_item_model.dart';
import 'package:recette/core/data/repositories/data_repository.dart';
import 'package:recette/core/data/services/database_helper.dart';

/// A generic repository for list-based features that handles common database operations.
abstract class BaseListRepository<T extends ListItem, C extends ListCategory> {
  final DataRepository<T> items;
  final DataRepository<C> categories;

  BaseListRepository({required this.items, required this.categories});

  Future<Map<C, List<T>>> getGroupedItems() async {
    final allCategories = await categories.getAll();
    final allItems = await items.getAll();

    final categoryMap = {for (var cat in allCategories) cat.id!: cat};
    final groupedItems = <C, List<T>>{};

    for (var cat in allCategories) {
      groupedItems[cat] = [];
    }

    for (final item in allItems) {
      final category = categoryMap[item.categoryId];
      if (category != null) {
        (groupedItems[category] ??= []).add(item);
      }
    }
    return groupedItems;
  }

  Future<void> reconcile({
    required List<T> itemsToAdd,
    required List<T> itemsToUpdate,
    required List<int> itemIdsToDelete,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final id in itemIdsToDelete) {
        batch.delete(items.tableName, where: 'id = ?', whereArgs: [id]);
      }
      for (final item in itemsToUpdate) {
        batch.update(items.tableName, item.toMap(), where: 'id = ?', whereArgs: [item.id]);
      }
      for (final item in itemsToAdd) {
        batch.insert(items.tableName, item.toMap());
      }
      await batch.commit(noResult: true);
    });
  }
}
