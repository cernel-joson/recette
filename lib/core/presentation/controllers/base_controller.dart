// In lib/core/presentation/controllers/base_controller.dart

import 'package:flutter/foundation.dart';

abstract class BaseController<T> with ChangeNotifier {
  List<T> _items = [];
  bool _isLoading = false;

  List<T> get items => _items;
  bool get isLoading => _isLoading;

  @protected
  Future<List<T>> fetchItems(); // Force subclasses to implement data fetching

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();
    _items = await fetchItems();
    _isLoading = false;
    // It's safe to call notifyListeners() here because this method will
    // now only be called from a mounted widget's initState.
    notifyListeners();
  }
}