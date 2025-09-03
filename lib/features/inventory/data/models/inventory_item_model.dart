import 'package:recette/core/data/models/list_item_model.dart';


// Implemented the ListItem interface to make this model compatible
// with the generic BaseListController.
class InventoryItem implements ListItem {
  @override
  final int? id;
  final String name;
  final String? brand;
  final String? quantity;
  final String? unit;
  final int? locationId; // This now maps to categoryId
  final String? healthRating;
  final String? notes;

  InventoryItem({
    this.id,
    required this.name,
    this.brand,
    this.quantity,
    this.unit,
    this.locationId,
    this.healthRating,
    this.notes,
  });

  // --- Implementation of the ListItem interface ---
  @override
  int? get categoryId => locationId;

  @override
  String get rawText {
    final parts = [quantity, unit, name];
    return parts.where((p) => p != null && p.isNotEmpty).join(' ');
  }

  @override
  String? get parsedName => name;

  @override
  String? get parsedQuantity {
    final parts = [quantity, unit];
    return parts.where((p) => p != null && p.isNotEmpty).join(' ');
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'quantity': quantity,
      'unit': unit,
      'location_id': locationId,
      'health_rating': healthRating,
      'notes': notes,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      name: map['name'] ?? 'Unknown Item',
      brand: map['brand'],
      quantity: map['quantity'],
      unit: map['unit'],
      locationId: map['location_id'],
      healthRating: map['health_rating'],
      notes: map['notes'],
    );
  }
}