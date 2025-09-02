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

  Future<void> reconcileMarkdownChanges() async {
    final newText = textController.text;
    if (newText == _originalMarkdownText) return;

    _isLoading = true;
    notifyListeners();

    final dmp = DiffMatchPatch();
    // --- FIX: Use correct snake_case method names from the library ---
    final diffs = dmp.diff(_originalMarkdownText, newText);
    dmp.diffCleanupSemantic(diffs);
    // --- END OF FIX ---

    final List<T> itemsToAdd = [];
    final List<T> itemsToUpdate = [];
    final List<int> itemIdsToDelete = [];

    int currentLine = 0;
    int currentCategoryId = categories.isNotEmpty ? categories.first.id ?? -1 : -1;

    for (final diff in diffs) {
      final linesInDiff = diff.text.split('\n');
      // --- FIX: Correctly calculate line count to avoid type errors and logic bugs ---
      int lineCount = linesInDiff.length;
      if (diff.operation != DIFF_INSERT) {
        // For deletes and equals, the number of lines processed is based on the original text structure
        lineCount = diff.text.isEmpty ? 0 : linesInDiff.length - (diff.text.endsWith('\n') ? 0 : 1);
      }
      // --- END OF FIX ---

      if (diff.operation == DIFF_EQUAL) {
        for(final line in linesInDiff) {
           if(line.startsWith('##')) {
              final catName = line.substring(3).trim();
              currentCategoryId = _categories.firstWhere((cat) => cat.name == catName, orElse: () => _categories.first).id!;
           }
        }
        currentLine += lineCount;
      } else if (diff.operation == DIFF_DELETE) {
         for (int i = 0; i < lineCount; i++) {
           final itemId = _lineIdMap[currentLine + i];
           if (itemId != null && itemId > 0) {
             itemIdsToDelete.add(itemId);
           }
         }
         currentLine += lineCount;
      } else if (diff.operation == DIFF_INSERT) {
         for (final line in linesInDiff) {
            if (line.trim().isEmpty) continue;
             if(line.startsWith('##')) {
                final catName = line.substring(3).trim();
                currentCategoryId = _categories.firstWhere((cat) => cat.name == catName, orElse: () => _categories.first).id!;
                continue;
            }

            final itemIdToUpdate = _lineIdMap[currentLine];
            
            if (itemIdToUpdate != null && itemIdsToDelete.contains(itemIdToUpdate)) {
              itemIdsToDelete.remove(itemIdToUpdate);
              final parsed = parser.parseLine(line);
              itemsToUpdate.add(createItemFromParsed(parsed, categoryId: currentCategoryId, id: itemIdToUpdate));
            } else {
              final parsed = parser.parseLine(line);
              itemsToAdd.add(createItemFromParsed(parsed, categoryId: currentCategoryId));
            }
        }
      }
    }
    
    await service.reconcileItems(
      itemsToAdd: itemsToAdd,
      itemsToUpdate: itemsToUpdate,
      itemIdsToDelete: itemIdsToDelete,
    );
    
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

