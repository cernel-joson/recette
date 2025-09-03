import 'package:flutter/material.dart';

/// A controller to manage the state of the main screen's dynamic UI elements,
/// such as the title and contextual action buttons.
class MainScreenController with ChangeNotifier {
  String _currentTitle = 'Home';
  Widget? _contextualAppBar;
  Widget? _bottomAppBar;
  Widget? _fab;

  String get currentTitle => _currentTitle;
  Widget? get contextualAppBar => _contextualAppBar;
  Widget? get bottomAppBar => _bottomAppBar;
  Widget? get fab => _fab;

  /// Called by the active feature screen to set its UI components.
  void setScreen({
    required String title,
    Widget? contextualAppBar,
    Widget? bottomAppBar,
    Widget? fab,
  }) {
    // Use post-frame callback to avoid build-time state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentTitle = title;
      _contextualAppBar = contextualAppBar;
      _bottomAppBar = bottomAppBar;
      _fab = fab;
      notifyListeners();
    });
  }
}