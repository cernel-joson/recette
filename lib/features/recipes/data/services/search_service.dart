import 'package:intelligent_nutrition_app/core/services/database_helper.dart';
import 'package:intelligent_nutrition_app/features/recipes/data/models/models.dart';

class SearchService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<Recipe>> searchRecipes(String rawQuery) async {
    final (sqlWhereClause, sqlArgs) = _parseQuery(rawQuery);
    return await _db.searchRecipes(sqlWhereClause, sqlArgs);
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