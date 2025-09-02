import 'package:recette/core/data/services/base_list_service.dart';
import 'package:recette/features/shopping_list/data/models/models.dart';
import 'package:recette/features/shopping_list/data/repositories/shopping_list_repository.dart';

class ShoppingListService extends BaseListService<ShoppingListItem, ShoppingListCategory> {
  ShoppingListService({ShoppingListRepository? repository})
      : super(repository ?? ShoppingListRepository());
}
