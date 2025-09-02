import 'package:flutter/foundation.dart';

/// A mixin that provides generic methods for managing a list within a
/// ChangeNotifier, automatically handling state changes.
///
/// It relies on the host class to provide a `markDirty()` method.
mixin ListManagerMixin<T> on ChangeNotifier {
  // This is an abstract method declaration. Any class using this mixin
  // MUST provide its own implementation of `markDirty`.
  void markDirty();

  /// Adds an item to the provided list and notifies listeners.
  void addItemToList(List<T> list, T newItem) {
    list.add(newItem);
    markDirty();
    notifyListeners();
  }

  /// Updates an item at a specific index in the list and notifies listeners.
  void updateItemInList(List<T> list, int index, T updatedItem) {
    if (index >= 0 && index < list.length) {
      list[index] = updatedItem;
      markDirty();
      notifyListeners();
    }
  }

  /// Removes an item from a specific index in the list and notifies listeners.
  void removeItemFromList(List<T> list, int index) {
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      markDirty();
      notifyListeners();
    }
  }
}