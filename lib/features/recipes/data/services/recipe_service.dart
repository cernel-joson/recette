import 'package:recette/core/core.dart';
import 'package:recette/core/jobs/data/models/job_model.dart';
import 'package:recette/core/jobs/data/repositories/job_repository.dart';
import 'package:recette/features/recipes/recipes.dart';

// Define a specific exception for this business rule.
class RecipeExistsException implements Exception {
  final String message;
  RecipeExistsException(this.message);
}

class RecipeService {
  final DatabaseHelper _db;
  final JobRepository _jobRepo;

  // Public constructor for app use
  RecipeService({DatabaseHelper? db, JobRepository? jobRepo})
      : _db = db ?? DatabaseHelper.instance,
        _jobRepo = jobRepo ?? JobRepository();

  /// Contains all business logic for saving a recipe.
  Future<void> saveRecipe(Recipe recipe, {int? sourceJobId}) async {
    final fingerprint = FingerprintHelper.generate(recipe);

    // 1. Check for duplicates only if it's a new recipe.
    if (recipe.id == null) {
      final bool exists = await _db.doesRecipeExist(fingerprint);
      if (exists) {
        throw RecipeExistsException(
            "An identical recipe already exists in your library.");
      }
    }

    final recipeToSave = recipe.copyWith(fingerprint: fingerprint);

    // 2. Perform the database operation.
    if (recipeToSave.id != null) {
      await _db.update(recipeToSave, recipeToSave.tags);
    } else {
      await _db.insert(recipeToSave, recipeToSave.tags);
    }

    // 3. Archive the source job if one was provided, completing the workflow.
    if (sourceJobId != null) {
      await _jobRepo.updateJobStatus(sourceJobId, JobStatus.archived);
    }
  }
}