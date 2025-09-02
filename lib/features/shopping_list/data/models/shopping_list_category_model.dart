import 'package:recette/core/data/models/list_item_model.dart';

class ShoppingListCategory implements ListCategory {
  @override
  final int? id;
  @override
  final String name;

  ShoppingListCategory({this.id, required this.name});

  @override
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory ShoppingListCategory.fromMap(Map<String, dynamic> map) {
    return ShoppingListCategory(id: map['id'], name: map['name']);
  }
}
