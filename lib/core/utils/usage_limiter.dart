// lib/helpers/usage_limiter.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A helper class to manage daily usage limits for features.
class UsageLimiter {
  final SharedPreferences _prefs;

  // Private constructor for testing
  @visibleForTesting
  UsageLimiter.internal(this._prefs);

  // Public factory constructor for normal use
  static Future<UsageLimiter> create() async {
    final prefs = await SharedPreferences.getInstance();
    return UsageLimiter.internal(prefs);
  }

  /// Checks if a feature is allowed to be used.
  Future<bool> isAllowed(
    String featureKey, {
    int maxUsages = 1,
    Duration duration = const Duration(minutes: 1),
  }) async {
    final usageTimestamps = _prefs.getStringList(featureKey) ?? [];
    final now = DateTime.now();

    // Filter out usages that are older than the specified duration.
    final recentUsages = usageTimestamps
        .map((t) => DateTime.fromMillisecondsSinceEpoch(int.parse(t)))
        .where((t) => now.difference(t) < duration)
        .toList();

    // If the number of recent usages is less than the max allowed, it's permitted.
    return recentUsages.length < maxUsages;
  }

  /// Records a new usage of a feature.
  Future<void> recordUsage(String featureKey) async {
    final usageTimestamps = _prefs.getStringList(featureKey) ?? [];
    final now = DateTime.now().millisecondsSinceEpoch;
    usageTimestamps.add(now.toString());
    await _prefs.setStringList(featureKey, usageTimestamps);
  }
  
  static const _scanLimit = 10; // Set the daily scan limit here.
  static const _scanCountKey = 'daily_scan_count';
  static const _lastScanDateKey = 'last_scan_date';

  // --- NEW: Central private helper ---
  static Future<(int, SharedPreferences)> _getTodaysCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateString();
    final lastScanDate = prefs.getString(_lastScanDateKey);
    int currentCount = prefs.getInt(_scanCountKey) ?? 0;

    if (lastScanDate != today) {
      currentCount = 0;
      // We also update the date right away
      await prefs.setString(_lastScanDateKey, today);
    }
    return (currentCount, prefs);
  }

  static Future<bool> canPerformScan() async {
    final (currentCount, _) = await _getTodaysCount();
    return currentCount < _scanLimit;
  }

  static Future<void> incrementScanCount() async {
    final (currentCount, prefs) = await _getTodaysCount();
    await prefs.setInt(_scanCountKey, currentCount + 1);
  }
  
  static Future<int> getRemainingScans() async {
    final (currentCount, _) = await _getTodaysCount();
    final remaining = _scanLimit - currentCount;
    return remaining > 0 ? remaining : 0;
  }

  static String _getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }
}