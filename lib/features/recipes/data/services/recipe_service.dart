import 'package:recette/core/jobs/logic/job_manager.dart';
import 'package:recette/features/recipes/recipes.dart';
import 'package:recette/features/recipes/data/repositories/recipe_repository.dart';
import 'package:recette/features/recipes/data/exceptions/recipe_exceptions.dart';

class RecipeService {
  final RecipeRepository _repository;
  final JobManager _jobManager;

  // 3. UPDATE CONSTRUCTOR FOR DEPENDENCY INJECTION
  RecipeService({
    RecipeRepository? repository,
    JobManager? jobManager,
  })  : _repository = repository ?? RecipeRepository(),
        _jobManager = jobManager ?? JobManager.instance;

  Future<List<Recipe>> getAllRecipes() => _repository.getAllRecipes();

  Future<Recipe?> getRecipeById(int id) => _repository.getRecipeById(id);

  Future<Recipe> createRecipe(Recipe recipe, {int? jobId}) async {
    // Business Logic: Enforce the no-duplicates rule.
    if (recipe.fingerprint != null) {
      final exists = await _repository.fingerprintExists(recipe.fingerprint!);
      if (exists) {
        throw RecipeExistsException('A recipe with this content already exists.');
      }
    }

    // The service handles the two-step process of creating a recipe and adding its tags
    final createdRecipe = await _repository.recipes.create(recipe);
    if (recipe.tags.isNotEmpty) {
      await _repository.addTagsToRecipe(createdRecipe.id!, recipe.tags);
    }
    
    if (jobId != null) {
      await _jobManager.archiveJob(jobId);
    }

    return createdRecipe;
  }

  Future<void> updateRecipe(Recipe recipe) async {
    // The service handles updating the recipe and its tags
    await _repository.recipes.update(recipe);
    await _repository.clearTagsForRecipe(recipe.id!);
    if (recipe.tags.isNotEmpty) {
      await _repository.addTagsToRecipe(recipe.id!, recipe.tags);
    }
  }

  Future<void> deleteRecipe(int id) async {
    await _repository.recipes.delete(id);
  }

  Future<List<Recipe>> getVariationsForRecipe(int parentRecipeId) async {
    // This is a more complex query that might be added to the repository later,
    // but for now, the service can filter the full list.
    final allRecipes = await getAllRecipes();
    return allRecipes
        .where((recipe) => recipe.parentRecipeId == parentRecipeId)
        .toList();
  }

  Future<void> batchInsertRecipes(List<Recipe> recipes) {
    return _repository.recipes.batchInsert(recipes);
  }

  Future<void> clearAllRecipes() async {
    await _repository.recipes.clear();
    await _repository.recipeTags.clear();
    await _repository.tags.clear();
  }

  /// Retrieves the most recently added recipes for the dashboard.
  Future<List<Recipe>> getRecentRecipes({int limit = 5}) {
    return _repository.getRecentRecipes(limit: limit);
  }

  Future<bool> doesRecipeExist(String fingerprint) async {
    return _repository.fingerprintExists(fingerprint);
  }
}