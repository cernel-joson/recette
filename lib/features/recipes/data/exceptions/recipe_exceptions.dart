/// An exception thrown when attempting to create a recipe that already exists.
class RecipeExistsException implements Exception {
  final String message;
  RecipeExistsException(this.message);

  @override
  String toString() => 'RecipeExistsException: $message';
}