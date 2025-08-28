import 'package:recette/core/data/repositories/data_repository.dart';

/// A simple model for user-defined item categories (e.g., 'Dairy', 'Vegetables').
class InventoryCategory implements DataModel {
  @override
  final int? id;
  final String name;

  InventoryCategory({this.id, required this.name});

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory InventoryCategory.fromMap(Map<String, dynamic> map) {
    return InventoryCategory(
      id: map['id'],
      name: map['name'],
    );
  }
}