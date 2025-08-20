// test/mocks/mock_recipe_parsing_service.dart

import 'package:mockito/annotations.dart';
import 'package:recette/features/recipes/data/services/recipe_parsing_service.dart';

// Because the service only has static methods, we need a dummy class to annotate.
class DummyRecipeParsingService extends RecipeParsingService {}

@GenerateMocks([DummyRecipeParsingService])
void main() {}