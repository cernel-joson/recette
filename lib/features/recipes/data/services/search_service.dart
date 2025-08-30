import 'package:recette/features/recipes/data/models/models.dart';
import 'package:recette/features/recipes/data/repositories/recipe_repository.dart';

// 1. ADD THIS CLASS DEFINITION AT THE TOP OF THE FILE
/// A simple data class to hold the components of a parsed SQL query.
class SearchQuery {
  final String whereClause;
  final List<Object?> whereArgs;

  SearchQuery(this.whereClause, this.whereArgs);
}

class SearchService {
  final RecipeRepository _repository;

  // 3. UPDATE CONSTRUCTOR FOR DEPENDENCY INJECTION
  SearchService({
    RecipeRepository? repository,
  })  : _repository = repository ?? RecipeRepository();

  Future<List<Recipe>> searchRecipes(String rawQuery) async {
    final (sqlWhereClause, sqlArgs) = _parseQuery(rawQuery);
    return await _repository.searchRecipes(sqlWhereClause, sqlArgs);
  }

  // 2. MAKE THE METHOD PUBLIC AND UPDATE ITS RETURN TYPE
  SearchQuery parseSearchQuery(String rawQuery) {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return SearchQuery('', []);
    }

    final parts = query.split(' ');
    final textTerms = <String>[];
    final tagTerms = <String>[];
    final excludedTagTerms = <String>[];
    final ingredientTerms = <String>[];
    final excludedIngredientTerms = <String>[];

    for (var part in parts) {
      if (part.startsWith('tag:')) {
        tagTerms.add(part.substring(4));
      } else if (part.startsWith('-tag:')) {
        excludedTagTerms.add(part.substring(5));
      } else if (part.startsWith('ingredient:')) {
        ingredientTerms.add(part.substring(11));
      } else if (part.startsWith('-ingredient:')) {
        excludedIngredientTerms.add(part.substring(12));
      } else {
        textTerms.add(part);
      }
    }

    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    // --- THIS IS THE FIX ---
    // Process each term type in a fixed order to ensure a consistent query string.
    
    // 1. Text Search
    if (textTerms.isNotEmpty) {
      final textQuery = textTerms.join(' ');
      whereClauses.add('(title LIKE ? OR description LIKE ?)');
      whereArgs.addAll(['%$textQuery%', '%$textQuery%']);
    }

    // 2. Included Tags
    if (tagTerms.isNotEmpty) {
      for (var tag in tagTerms) {
        whereClauses.add(
            'id IN (SELECT recipeId FROM recipe_tags WHERE tagId IN (SELECT id FROM tags WHERE name = ?))');
        whereArgs.add(tag);
      }
    }
    
    // 3. Included Ingredients
    if (ingredientTerms.isNotEmpty) {
      for (var ingredient in ingredientTerms) {
        whereClauses.add('ingredients LIKE ?');
        whereArgs.add('%"name":"%$ingredient%"%');
      }
    }

    // 4. Excluded Ingredients
    if (excludedIngredientTerms.isNotEmpty) {
      for (var ingredient in excludedIngredientTerms) {
        whereClauses.add('ingredients NOT LIKE ?');
        whereArgs.add('%"name":"%$ingredient%"%');
      }
    }

    // 5. Excluded Tags
    if (excludedTagTerms.isNotEmpty) {
      for (var tag in excludedTagTerms) {
        whereClauses.add(
            'id NOT IN (SELECT recipeId FROM recipe_tags WHERE tagId IN (SELECT id FROM tags WHERE name = ?))');
        whereArgs.add(tag);
      }
    }

    return SearchQuery(whereClauses.join(' AND '), whereArgs);
  }

  /// The heart of the parser.
  (String, List<Object?>) _parseQuery(String rawQuery) {
    if (rawQuery.trim().isEmpty) {
      return ('id = ?', [-1]);
    }

    final List<String> whereClauses = [];
    final List<Object?> sqlArgs = [];

    // Split the query by spaces, but respect quoted strings.
    final RegExp querySplitter = RegExp(r'''("([^"]*)"|'([^']*)'|(\S+))''');
    final matches = querySplitter.allMatches(rawQuery);

    List<String> terms = matches.map((m) {
      if (m.group(2) != null) return m.group(2)!; // "quoted"
      if (m.group(3) != null) return m.group(3)!; // 'quoted'
      return m.group(4)!; // non-quoted
    }).toList();
    
    // This will hold terms that are not keywords, for a general text search.
    List<String> generalSearchTerms = [];

    for (var term in terms) {
      bool isNegated = term.startsWith('-');
      if (isNegated) {
        term = term.substring(1); // Remove the '-'
      }

      if (term.startsWith('tag:')) {
        final tag = term.substring(4);
        // We need a subquery to see if a recipe is linked to this tag.
        final existsOperator = isNegated ? 'NOT EXISTS' : 'EXISTS';
        whereClauses.add('''
          $existsOperator (
            SELECT 1 FROM recipe_tags rt
            JOIN tags t ON t.id = rt.tagId
            WHERE rt.recipeId = recipes.id AND t.name = ?
          )
        ''');
        sqlArgs.add(tag.toLowerCase());
      } else if (term.startsWith('ingredient:')) {
        final ingredient = term.substring(11);
        final likeOperator = isNegated ? 'NOT LIKE' : 'LIKE';
        // The ingredients are stored as a JSON string, so we can search it directly.
        whereClauses.add('ingredients $likeOperator ?');
        sqlArgs.add('%"name":"%$ingredient%"%');
      } else {
        generalSearchTerms.add(term);
      }
    }

    // Handle the general, non-keyword terms as a title search.
    if (generalSearchTerms.isNotEmpty) {
      whereClauses.add('title LIKE ?');
      sqlArgs.add('%${generalSearchTerms.join(' ')}%');
    }

    return (whereClauses.join(' AND '), sqlArgs);
  }
}