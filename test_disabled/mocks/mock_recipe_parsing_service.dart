// test/mocks/mock_recipe_analysis_service.dart

import 'package:mockito/annotations.dart';
import 'package:recette/features/recipes/services/recipe_analysis_service.dart';

// Because the service only has static methods, we need a dummy class to annotate.
class DummyRecipeAnalysisService extends RecipeAnalysisService {}

@GenerateMocks([DummyRecipeAnalysisService])
void main() {}