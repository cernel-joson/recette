// test/services/inventory_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:recette/features/inventory/data/models/inventory_item_model.dart';
import 'package:recette/features/inventory/services/inventory_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Use a mock database helper to isolate the service logic.
// This allows us to test the service without needing a real database.
import '../mocks/mock_database_helper.mocks.dart';

void main() {
  // Set up sqflite_common_ffi for testing on desktop environments
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late MockDatabaseHelper mockDatabaseHelper;
  late InventoryService inventoryService;
  late MockDatabase mockDatabase;

  setUp(() {
    // Create new instances for each test to ensure they are isolated.
    mockDatabaseHelper = MockDatabaseHelper();
    inventoryService = InventoryService.internal(mockDatabaseHelper);
    mockDatabase = MockDatabase();

    // When the service asks for the database, return our mock database instance.
    when(mockDatabaseHelper.database).thenAnswer((_) async => mockDatabase);
  });

  group('InventoryService Tests', () {
    test('getInventory returns a list of items from the database', () async {
      // Arrange: Define what the mock database should return when queried.
      final mockDbResponse = [
        {'id': 1, 'name': 'Milk', 'quantity': '1', 'unit': 'gallon'},
        {'id': 2, 'name': 'Eggs', 'quantity': '12', 'unit': 'count'},
      ];
      when(mockDatabase.query(any, orderBy: anyNamed('orderBy')))
          .thenAnswer((_) async => mockDbResponse);

      // Act: Call the method we are testing.
      final items = await inventoryService.getInventory();

      // Assert: Verify the result.
      expect(items, isA<List<InventoryItem>>());
      expect(items.length, 2);
      expect(items.first.name, 'Milk');
    });

    test('addItem inserts a new item into the database', () async {
      // Arrange
      final newItem = InventoryItem(name: 'Bread', quantity: '1', unit: 'loaf');
      // We expect the 'insert' method on the mock database to be called.
      when(mockDatabase.insert(any, any)).thenAnswer((_) async => 3); // Return a dummy ID

      // Act
      await inventoryService.addItem(newItem);

      // Assert: Verify that the 'insert' method was called exactly once
      // with the correct table name and data.
      verify(mockDatabase.insert('inventory', newItem.toMap())).called(1);
    });

    test('updateItem calls the database update method', () async {
      // Arrange
      final itemToUpdate = InventoryItem(id: 1, name: 'Almond Milk');
      when(mockDatabase.update(any, any,
              where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
          .thenAnswer((_) async => 1);

      // Act
      await inventoryService.updateItem(itemToUpdate);

      // Assert
      verify(mockDatabase.update('inventory', itemToUpdate.toMap(),
          where: 'id = ?', whereArgs: [itemToUpdate.id])).called(1);
    });

    test('deleteItem calls the database delete method', () async {
      // Arrange
      const itemIdToDelete = 5;
      when(mockDatabase.delete(any,
              where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
          .thenAnswer((_) async => 1);

      // Act
      await inventoryService.deleteItem(itemIdToDelete);

      // Assert
      verify(mockDatabase.delete('inventory',
          where: 'id = ?', whereArgs: [itemIdToDelete])).called(1);
    });
  });
}
