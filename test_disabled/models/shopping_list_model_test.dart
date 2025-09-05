// test/models/shopping_list_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:recette/features/shopping_list/shopping_list.dart';

void main() {
  group('ShoppingListItem Model Tests', () {
    final testItem = ShoppingListItem(id: 1, name: 'Apples', isChecked: true);

    test('toMap serializes correctly', () {
      // Act
      final itemMap = testItem.toMap();

      // Assert
      expect(itemMap['id'], 1);
      expect(itemMap['name'], 'Apples');
      // Check that the boolean is correctly converted to an integer (1 for true)
      expect(itemMap['is_checked'], 1);
    });

    test('fromMap deserializes correctly', () {
      // Arrange
      final itemMap = {'id': 1, 'name': 'Apples', 'is_checked': 1};

      // Act
      final item = ShoppingListItem.fromMap(itemMap);

      // Assert
      expect(item.id, 1);
      expect(item.name, 'Apples');
      // Check that the integer is correctly converted to a boolean
      expect(item.isChecked, isTrue);
    });

    test('fromMap handles false values', () {
      // Arrange
      final itemMap = {'id': 2, 'name': 'Bread', 'is_checked': 0};

      // Act
      final item = ShoppingListItem.fromMap(itemMap);

      // Assert
      expect(item.isChecked, isFalse);
    });
  });
}