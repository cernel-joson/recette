import 'dart:async';
import 'package:flutter/material.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:recette/core/data/models/list_item_model.dart';
import 'package:recette/core/services/base_list_service.dart';
import 'package:recette/core/utils/markdown_parser.dart';

abstract class BaseListController<T extends ListItem, C extends ListCategory> with ChangeNotifier {
  final BaseListService<T, C> service;
  final MarkdownParser<T, C> parser = MarkdownParser<T, C>();

  // State
  bool _isLoading = true;
  Map<C, List<T>> _groupedItems = {};
  List<C> _categories = [];
  Timer? _debounce;

  // Markdown Editor State
  final TextEditingController textController = TextEditingController();
  String _originalMarkdownText = '';
  Map<int, int> _lineIdMap = {};

  // Getters
  bool get isLoading => _isLoading;
  Map<C, List<T>> get groupedItems => _groupedItems;
  List<C> get categories => _categories;

  BaseListController(this.service) {
    textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    textController.removeListener(_onTextChanged);
    textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () {
      if (textController.text != _originalMarkdownText) {
        reconcileMarkdownChanges();
      }
    });
  }

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
      _lineIdMap[currentLine] = -category.id!;
      currentLine++;
      for (final item in items) {
        _lineIdMap[currentLine] = item.id!;
        currentLine++;
      }
      if (items.isNotEmpty) {
        currentLine++;
      }
    });
  }
  
  T createItemFromParsed(Map<String, String> parsed, {required int categoryId, int? id});
  C createCategory(String name);
  
  Future<void> reconcileMarkdownChanges() async {
    final newText = textController.text;
    if (newText == _originalMarkdownText) return;

    _isLoading = true;
    notifyListeners();

    final newStructure = parser.parseMarkdownToStructure(newText);
    final newCategoryNames = newStructure.keys.toSet();

    final existingCategories = await service.getAllCategories();
    final existingCategoryMap = { for (var cat in existingCategories) cat.name: cat };

    final categoriesToCreate = newCategoryNames.where((name) => !existingCategoryMap.containsKey(name));
    for (final name in categoriesToCreate) {
      await service.addCategory(createCategory(name));
    }

    final categoriesToDelete = existingCategoryMap.values.where((cat) {
      return !newCategoryNames.contains(cat.name) && cat.name != 'Uncategorized';
    });
    for (final category in categoriesToDelete) {
      await service.deleteCategory(category.id!);
    }

    final allCategories = await service.getAllCategories();
    final categoryNameToIdMap = { for (var cat in allCategories) cat.name: cat.id! };
    
    final allExistingItems = await service.getAllItems();
    final existingItemsByRawText = { for (var item in allExistingItems) item.rawText: item };

    final itemsToAdd = <T>[];
    final itemsToUpdate = <T>[];
    final Set<int> itemsToKeep = {};

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

    await service.reconcileItems(
      itemsToAdd: itemsToAdd,
      itemsToUpdate: itemsToUpdate,
      itemIdsToDelete: itemIdsToDelete,
    );

    await loadItems();
  }

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

