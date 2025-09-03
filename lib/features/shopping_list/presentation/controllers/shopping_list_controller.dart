import 'package:recette/core/presentation/controllers/base_list_controller.dart';
import 'package:recette/features/shopping_list/data/models/models.dart';
import 'package:recette/features/shopping_list/data/services/shopping_list_service.dart';

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
  
  // Implement the new required abstract method from the base controller.
  @override
  ShoppingListCategory createCategory(String name) {
    // This provides the base controller with a way to create a new category
    // object when it detects one in the markdown, without needing to know the
    // specific implementation details of ShoppingListCategory.
    return ShoppingListCategory(name: name);
  }

  // Shopping list specific logic
  Future<void> toggleItem(ShoppingListItem item) async {
    final updatedItem = item.copyWith(isChecked: !item.isChecked);
    await super.updateItem(updatedItem);
  }
}
