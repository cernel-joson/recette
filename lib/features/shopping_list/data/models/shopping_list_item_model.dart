import 'package:flutter/foundation.dart';
import 'package:recette/core/data/models/list_item_model.dart';

@immutable
class ShoppingListItem implements ListItem {
  @override
  final int? id;
  @override
  final int? categoryId;

  @override
  final String rawText;
  @override
  final String? parsedName;
  @override
  final String? parsedQuantity;

  final bool isChecked;

  const ShoppingListItem({
    this.id,
    this.categoryId,
    required this.rawText,
    this.parsedName,
    this.parsedQuantity,
    this.isChecked = false,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'raw_text': rawText,
      'parsed_name': parsedName,
      'parsed_quantity': parsedQuantity,
      'is_checked': isChecked ? 1 : 0,
    };
  }

  factory ShoppingListItem.fromMap(Map<String, dynamic> map) {
    return ShoppingListItem(
      id: map['id'],
      categoryId: map['category_id'],
      rawText: map['raw_text'] ?? '',
      parsedName: map['parsed_name'],
      parsedQuantity: map['parsed_quantity'],
      isChecked: map['is_checked'] == 1,
    );
  }

  ShoppingListItem copyWith({
    int? id,
    int? categoryId,
    String? rawText,
    String? parsedName,
    String? parsedQuantity,
    bool? isChecked,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      rawText: rawText ?? this.rawText,
      parsedName: parsedName ?? this.parsedName,
      parsedQuantity: parsedQuantity ?? this.parsedQuantity,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}
