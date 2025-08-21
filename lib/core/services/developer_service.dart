// lib/core/services/developer_service.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeveloperService with ChangeNotifier {
  static const _devModeKey = 'developer_mode_enabled';
  bool _isDeveloperMode = false;

  bool get isDeveloperMode => _isDeveloperMode;

  DeveloperService() {
    _loadDeveloperMode();
  }

  Future<void> _loadDeveloperMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isDeveloperMode = prefs.getBool(_devModeKey) ?? false;
    notifyListeners();
  }

  Future<void> enableDeveloperMode() async {
    if (_isDeveloperMode) return; // No need to enable if already on
    final prefs = await SharedPreferences.getInstance();
    _isDeveloperMode = true;
    await prefs.setBool(_devModeKey, true);
    notifyListeners();
    debugPrint("--- Developer Mode Enabled ---");
  }

  Future<void> disableDeveloperMode() async {
    if (!_isDeveloperMode) return; // No need to disable if already off
    final prefs = await SharedPreferences.getInstance();
    _isDeveloperMode = false;
    await prefs.setBool(_devModeKey, false);
    notifyListeners();
    debugPrint("--- Developer Mode Disabled ---");
  }
}