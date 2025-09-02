import 'package:recette/core/presentation/controllers/base_list_controller.dart';
import 'package:recette/features/shopping_list/data/models/models.dart';
import 'package:recette/features/shopping_list/data/services/shopping_list_service.dart';
import 'package:recette/features/shopping_list/data/models/shopping_list_item_model.dart';
import 'package:recette/features/shopping_list/data/models/shopping_list_category_model.dart';

class ShoppingListController extends BaseListController<ShoppingListItem, ShoppingListCategory> {
  ShoppingListController({ShoppingListService? shoppingListService})
      : super(shoppingListService ?? ShoppingListService());

  @override
  ShoppingListItem createItemFromParsed(Map<String, String> parsed, {required int categoryId, int? id}) {
    return ShoppingListItem(
      id: id,
      categoryId: categoryId,
      rawText: parsed['rawText']!,
      parsedName: parsed['parsedName'],
      parsedQuantity: parsed['parsedQuantity'],
    );
  }

  // Shopping list specific logic
  Future<void> toggleItem(ShoppingListItem item) async {
    final updatedItem = item.copyWith(isChecked: !item.isChecked);
    await super.updateItem(updatedItem);
  }
}
