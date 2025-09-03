import 'package:flutter/material.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:recette/core/data/models/list_item_model.dart';
import 'package:recette/core/data/services/base_list_service.dart';
import 'package:recette/core/data/utils/markdown_parser.dart';

abstract class BaseListController<T extends ListItem, C extends ListCategory> with ChangeNotifier {
  final BaseListService<T, C> service;
  final MarkdownParser<T, C> parser = MarkdownParser<T, C>();

  // State
  bool _isLoading = true;
  Map<C, List<T>> _groupedItems = {};
  List<C> _categories = [];

  // Markdown Editor State
  final TextEditingController textController = TextEditingController();
  String _originalMarkdownText = '';
  Map<int, int> _lineIdMap = {};

  // Getters
  bool get isLoading => _isLoading;
  Map<C, List<T>> get groupedItems => _groupedItems;
  List<C> get categories => _categories;

  BaseListController(this.service);

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    _groupedItems = await service.getGroupedItems();
    _categories = _groupedItems.keys.toList();
    _generateMarkdownState();

    _isLoading = false;
    notifyListeners();
  }

  void _generateMarkdownState() {
    _originalMarkdownText = parser.generateMarkdown(_groupedItems);
    textController.text = _originalMarkdownText;
    _lineIdMap.clear();

    int currentLine = 0;
    _groupedItems.forEach((category, items) {
      // Use a negative ID to distinguish categories from items in the map
      _lineIdMap[currentLine] = -category.id!;
      currentLine++;
      for (final item in items) {
        _lineIdMap[currentLine] = item.id!;
        currentLine++;
      }
      // Account for the blank line between categories
      if (items.isNotEmpty) {
        currentLine++;
      }
    });
  }
  
  T createItemFromParsed(Map<String, String> parsed, {required int categoryId, int? id});

  /// Abstract method for concrete controllers to implement category creation.
  C createCategory(String name);
  
  // The reconciliation logic is now a complete sync, handling additions,
  // updates, and deletions for both items and categories.
  Future<void> reconcileMarkdownChanges() async {
    final newText = textController.text;
    if (newText == _originalMarkdownText) return;

    _isLoading = true;
    notifyListeners();

    // 1. Parse the new markdown into a structured map
    final newStructure = parser.parseMarkdownToStructure(newText);
    final newCategoryNames = newStructure.keys.toSet();

    // 2. Get current categories from the database
    final existingCategories = await service.getAllCategories();
    final existingCategoryMap = { for (var cat in existingCategories) cat.name: cat };

    // 3. Create any new categories found in the markdown
    final categoriesToCreate = newCategoryNames.where((name) => !existingCategoryMap.containsKey(name));
    for (final name in categoriesToCreate) {
      await service.addCategory(createCategory(name));
    }

    // 4. Delete any old categories that are no longer in the markdown
    final categoriesToDelete = existingCategoryMap.values.where((cat) {
      // Don't delete a category if it's still in the new text.
      // Also, never delete the default "Uncategorized" category.
      return !newCategoryNames.contains(cat.name) && cat.name != 'Uncategorized';
    });
    for (final category in categoriesToDelete) {
      await service.deleteCategory(category.id!);
    }

    // 5. Re-fetch all categories to get a complete, updated map with IDs
    final allCategories = await service.getAllCategories();
    final categoryNameToIdMap = { for (var cat in allCategories) cat.name: cat.id! };
    
    // 6. Get all existing items from the database
    final allExistingItems = await service.getAllItems();
    final existingItemsByRawText = { for (var item in allExistingItems) item.rawText: item };

    // 7. Determine item changes (add, update, delete)
    final itemsToAdd = <T>[];
    final itemsToUpdate = <T>[];
    final Set<int> itemsToKeep = {}; // Track items that are still in the new text

    newStructure.forEach((categoryName, parsedItems) {
      final categoryId = categoryNameToIdMap[categoryName]!;
      for (final parsedItemData in parsedItems) {
        final rawText = parsedItemData['rawText']!;
        final existingItem = existingItemsByRawText[rawText];

        if (existingItem != null) {
          itemsToKeep.add(existingItem.id!);
          if (existingItem.categoryId != categoryId) {
            final updatedItem = createItemFromParsed(parsedItemData, categoryId: categoryId, id: existingItem.id);
            itemsToUpdate.add(updatedItem);
          }
        } else {
          itemsToAdd.add(createItemFromParsed(parsedItemData, categoryId: categoryId));
        }
      }
    });

    final allExistingItemIds = allExistingItems.map((item) => item.id!).toSet();
    final itemIdsToDelete = allExistingItemIds.difference(itemsToKeep).toList();

    // 8. Call the service to perform the database transaction for items
    await service.reconcileItems(
      itemsToAdd: itemsToAdd,
      itemsToUpdate: itemsToUpdate,
      itemIdsToDelete: itemIdsToDelete,
    );

    // 9. Reload the state from the database to reflect all changes
    await loadItems();
  }

  // --- Methods for Visual Editor ---
  Future<void> addItem(T item) async {
    await service.addItem(item);
    await loadItems();
  }

  Future<void> updateItem(T item) async {
    await service.updateItem(item);
    await loadItems();
  }

  Future<void> deleteItem(int id) async {
    await service.deleteItem(id);
    await loadItems();
  }
}

