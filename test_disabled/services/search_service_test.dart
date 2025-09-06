// test/services/search_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:recette/features/recipes/services/search_service.dart';

void main() {
  late SearchService searchService;

  setUp(() {
    searchService = SearchService();
  });

  group('SearchService Query Parsing', () {
    test('parses a simple text query', () {
      // Arrange
      const query = 'chicken soup';

      // Act
      final result = searchService.parseSearchQuery(query);

      // Assert
      expect(result.whereClause, '(title LIKE ? OR description LIKE ?)');
      expect(result.whereArgs, ['%chicken soup%', '%chicken soup%']);
    });

    test('parses a single tag query', () {
      // Arrange
      const query = 'tag:dinner';

      // Act
      final result = searchService.parseSearchQuery(query);

      // Assert
      expect(result.whereClause, 'id IN (SELECT recipeId FROM recipe_tags WHERE tagId IN (SELECT id FROM tags WHERE name = ?))');
      expect(result.whereArgs, ['dinner']);
    });

    test('parses an excluded tag query', () {
      // Arrange
      const query = '-tag:spicy';

      // Act
      final result = searchService.parseSearchQuery(query);

      // Assert
      expect(result.whereClause, 'id NOT IN (SELECT recipeId FROM recipe_tags WHERE tagId IN (SELECT id FROM tags WHERE name = ?))');
      expect(result.whereArgs, ['spicy']);
    });

    test('parses a single ingredient query', () {
      // Arrange
      const query = 'ingredient:garlic';

      // Act
      final result = searchService.parseSearchQuery(query);

      // Assert
      expect(result.whereClause, 'ingredients LIKE ?');
      expect(result.whereArgs, ['%"name":"%garlic%"%']);
    });

    test('parses an excluded ingredient query', () {
      // Arrange
      const query = '-ingredient:cilantro';

      // Act
      final result = searchService.parseSearchQuery(query);

      // Assert
      expect(result.whereClause, 'ingredients NOT LIKE ?');
      expect(result.whereArgs, ['%"name":"%cilantro%"%']);
    });

    test('parses a complex query with multiple terms', () {
      // Arrange
      const query = 'chicken tag:dinner -ingredient:cilantro -tag:dessert';

      // Act
      final result = searchService.parseSearchQuery(query);

      // Assert
      expect(result.whereClause, '(title LIKE ? OR description LIKE ?) AND id IN (SELECT recipeId FROM recipe_tags WHERE tagId IN (SELECT id FROM tags WHERE name = ?)) AND ingredients NOT LIKE ? AND id NOT IN (SELECT recipeId FROM recipe_tags WHERE tagId IN (SELECT id FROM tags WHERE name = ?))');
      expect(result.whereArgs, ['%chicken%', '%chicken%', 'dinner', '%"name":"%cilantro%"%', 'dessert']);
    });

     test('handles an empty query gracefully', () {
      // Arrange
      const query = ' ';

      // Act
      final result = searchService.parseSearchQuery(query);

      // Assert
      expect(result.whereClause, '');
      expect(result.whereArgs, isEmpty);
    });
  });
}