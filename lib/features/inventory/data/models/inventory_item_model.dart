import 'package:recette/core/data/repositories/data_repository.dart';

/// The core model representing a single item in the user's inventory.
class InventoryItem implements DataModel {
  @override
  final int? id;
  final String name;
  final String? brand;
  final String? quantity;
  final String? unit;
  final int? locationId;
  final int? categoryId;
  final String? healthRating;
  final String? notes;

  InventoryItem({
    this.id,
    required this.name,
    this.brand,
    this.quantity,
    this.unit,
    this.locationId,
    this.categoryId,
    this.healthRating,
    this.notes,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'quantity': quantity,
      'unit': unit,
      'location_id': locationId,
      'category_id': categoryId,
      'health_rating': healthRating,
      'notes': notes,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      name: map['name'],
      brand: map['brand'],
      quantity: map['quantity'],
      unit: map['unit'],
      locationId: map['location_id'],
      categoryId: map['category_id'],
      healthRating: map['health_rating'],
      notes: map['notes'],
    );
  }
}