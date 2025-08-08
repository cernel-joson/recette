// lib/features/inventory/data/models/inventory_models.dart

/// A simple model for user-defined storage locations (e.g., 'Fridge', 'Pantry').
class Location {
  final int? id;
  final String name;
  final String? iconName;

  Location({this.id, required this.name, this.iconName});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id'],
      name: map['name'],
      iconName: map['icon_name'],
    );
  }
}

/// A simple model for user-defined item categories (e.g., 'Dairy', 'Vegetables').
class Category {
  final int? id;
  final String name;

  Category({this.id, required this.name});

   Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
    );
  }
}

/// The core model representing a single item in the user's inventory.
class InventoryItem {
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