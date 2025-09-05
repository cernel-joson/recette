// test/services/shopping_list_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:recette/features/shopping_list/shopping_list.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../mocks/mock_database_helper.mocks.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late MockDatabaseHelper mockDatabaseHelper;
  late ShoppingListService shoppingListService;
  late MockDatabase mockDatabase;

  setUp(() {
    mockDatabaseHelper = MockDatabaseHelper();
    // We'll create an internal constructor in the service to allow injecting the mock.
    shoppingListService = ShoppingListService.internal(mockDatabaseHelper);
    mockDatabase = MockDatabase();

    when(mockDatabaseHelper.database).thenAnswer((_) async => mockDatabase);
  });

  group('ShoppingListService Tests', () {
    test('getItems returns a list of shopping list items', () async {
      // Arrange
      final mockResponse = [
        {'id': 1, 'name': 'Apples', 'is_checked': 0},
        {'id': 2, 'name': 'Milk', 'is_checked': 1},
      ];
      when(mockDatabase.query(any, orderBy: anyNamed('orderBy')))
          .thenAnswer((_) async => mockResponse);

      // Act
      final items = await shoppingListService.getItems();

      // Assert
      expect(items.length, 2);
      expect(items.first.name, 'Apples');
      expect(items.last.isChecked, isTrue);
    });

    test('addItem inserts a new item', () async {
      // Arrange
      const itemName = 'Bread';
      when(mockDatabase.insert(any, any)).thenAnswer((_) async => 3);

      // Act
      await shoppingListService.addItem(itemName);

      // Assert
      verify(mockDatabase.insert(
        'shopping_list_items',
        {'name': itemName, 'is_checked': 0},
      )).called(1);
    });

    test('addItem does not insert empty strings', () async {
      // Act
      await shoppingListService.addItem('  '); // Whitespace only

      // Assert: Verify that the insert method was NEVER called.
      verifyNever(mockDatabase.insert(any, any));
    });

    test('updateItem updates an existing item', () async {
      // Arrange
      final updatedItem =
          ShoppingListItem(id: 1, name: 'Green Apples', isChecked: true);
      when(mockDatabase.update(any, any,
              where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
          .thenAnswer((_) async => 1);

      // Act
      await shoppingListService.updateItem(updatedItem);

      // Assert
      verify(mockDatabase.update(
        'shopping_list_items',
        updatedItem.toMap(),
        where: 'id = ?',
        whereArgs: [updatedItem.id],
      )).called(1);
    });
  });
}