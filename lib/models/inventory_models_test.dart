// test/models/inventory_models_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:recette/features/inventory/data/models/inventory_models.dart';

void main() {
  group('InventoryItem Model Tests', () {
    final testItem = InventoryItem(
      id: 1,
      name: 'Milk',
      brand: 'Generic',
      quantity: '1',
      unit: 'gallon',
      locationId: 10,
      categoryId: 20,
      healthRating: 'GREEN',
      notes: 'Use first',
    );

    test('toMap serializes correctly', () {
      // Act
      final itemMap = testItem.toMap();

      // Assert
      expect(itemMap['id'], 1);
      expect(itemMap['name'], 'Milk');
      expect(itemMap['location_id'], 10);
      expect(itemMap['health_rating'], 'GREEN');
    });

    test('fromMap deserializes correctly', () {
      // Arrange
      final itemMap = {
        'id': 1,
        'name': 'Milk',
        'brand': 'Generic',
        'quantity': '1',
        'unit': 'gallon',
        'location_id': 10,
        'category_id': 20,
        'health_rating': 'GREEN',
        'notes': 'Use first',
      };

      // Act
      final item = InventoryItem.fromMap(itemMap);

      // Assert
      expect(item.id, 1);
      expect(item.name, 'Milk');
      expect(item.locationId, 10);
      expect(item.notes, 'Use first');
    });
  });

  group('Location Model Tests', () {
    final testLocation = Location(id: 1, name: 'Fridge', iconName: 'snowflake');

    test('toMap serializes correctly', () {
      final locationMap = testLocation.toMap();
      expect(locationMap['id'], 1);
      expect(locationMap['name'], 'Fridge');
      expect(locationMap['icon_name'], 'snowflake');
    });

    test('fromMap deserializes correctly', () {
      final locationMap = {'id': 1, 'name': 'Fridge', 'icon_name': 'snowflake'};
      final location = Location.fromMap(locationMap);
      expect(location.id, 1);
      expect(location.name, 'Fridge');
      expect(location.iconName, 'snowflake');
    });
  });

  group('Category Model Tests', () {
    final testCategory = Category(id: 1, name: 'Dairy');

    test('toMap serializes correctly', () {
      final categoryMap = testCategory.toMap();
      expect(categoryMap['id'], 1);
      expect(categoryMap['name'], 'Dairy');
    });

    test('fromMap deserializes correctly', () {
      final categoryMap = {'id': 1, 'name': 'Dairy'};
      final category = Category.fromMap(categoryMap);
      expect(category.id, 1);
      expect(category.name, 'Dairy');
    });
  });
}