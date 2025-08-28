import 'package:flutter/foundation.dart';
import 'package:recette/core/data/repositories/data_repository.dart';

@immutable
class ShoppingListItem implements DataModel {
  @override
  final int? id;
  final String name;
  final bool isChecked;

  ShoppingListItem({
    this.id,
    required this.name,
    this.isChecked = false
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_checked': isChecked ? 1 : 0,
    };
  }

  factory ShoppingListItem.fromMap(Map<String, dynamic> map) {
    return ShoppingListItem(
      id: map['id'],
      name: map['name'],
      isChecked: map['is_checked'] == 1,
    );
  }

  ShoppingListItem copyWith({int? id, String? name, bool? isChecked}) {
    return ShoppingListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}