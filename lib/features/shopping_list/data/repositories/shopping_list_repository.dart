import 'package:recette/core/data/repositories/base_list_repository.dart';
import 'package:recette/core/data/repositories/data_repository.dart';
import 'package:recette/features/shopping_list/data/models/models.dart';

class ShoppingListRepository extends BaseListRepository<ShoppingListItem, ShoppingListCategory> {
  ShoppingListRepository()
      : super(
          items: DataRepository<ShoppingListItem>(
            tableName: 'shopping_list_items',
            fromMap: (map) => ShoppingListItem.fromMap(map),
          ),
          categories: DataRepository<ShoppingListCategory>(
            tableName: 'shopping_list_categories',
            fromMap: (map) => ShoppingListCategory.fromMap(map),
          ),
        );
}
