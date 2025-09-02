import 'package:recette/core/data/repositories/data_repository.dart';

/// The abstract contract for a category in a list (e.g., a Location, a Store Aisle).
// --- FIX: Use `implements` instead of `extends` for an interface class ---
abstract class ListCategory implements DataModel {
  String get name;
}

/// The abstract contract for an item within a list.
// --- FIX: Use `implements` instead of `extends` for an interface class ---
abstract class ListItem implements DataModel {
  String get rawText;
  String? get parsedName;
  String? get parsedQuantity;
  int? get categoryId; // Foreign key to its category
}

