import 'package:flutter/material.dart';
import 'package:recette/core/data/models/list_item_model.dart';
import 'package:recette/core/presentation/controllers/base_list_controller.dart';
import 'package:recette/core/presentation/widgets/item_edit_dialog.dart';

class DialogUtils {
  /// Shows a generic dialog to add or edit a ListItem.
  /// It handles the result and calls the appropriate controller method.
  static Future<void> showItemEditDialog<T extends ListItem, C extends ListCategory>({
    required BuildContext context,
    required BaseListController<T, C> controller,
    T? item, // The item to edit (if any)
    int? categoryId, // The category to add to (if new)
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ItemEditDialog(
        item: item,
        categories: controller.categories,
        initialCategoryId: categoryId,
      ),
    );

    if (result != null) {
      final parsedData = controller.parser.parseLine(
        '${result['quantity']} ${result['name']}'.trim()
      );
      
      final itemToSave = controller.createItemFromParsed(
        parsedData,
        categoryId: result['categoryId'],
        id: item?.id, // Keep the original ID if editing
      );

      if (item == null) {
        await controller.addItem(itemToSave);
      } else {
        await controller.updateItem(itemToSave);
      }
    }
  }
}
