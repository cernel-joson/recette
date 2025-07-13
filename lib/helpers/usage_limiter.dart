// lib/helpers/usage_limiter.dart

import 'package:shared_preferences/shared_preferences.dart';

/// A helper class to manage daily usage limits for features.
class UsageLimiter {
  static const _scanLimit = 5; // Set the daily scan limit here.
  static const _scanCountKey = 'daily_scan_count';
  static const _lastScanDateKey = 'last_scan_date';

  /// Checks if the user is allowed to perform a scan.
  ///
  /// Returns `true` if the limit has not been reached, `false` otherwise.
  static Future<bool> canPerformScan() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateString();

    final lastScanDate = prefs.getString(_lastScanDateKey);
    int currentCount = prefs.getInt(_scanCountKey) ?? 0;
    print(currentCount);
    print(lastScanDate);
    print(today);
    // If the last scan was not today, reset the counter.
    if (lastScanDate != today) {
      currentCount = 0;
      await prefs.setString(_lastScanDateKey, today);
    }

    return currentCount < _scanLimit;
  }

  /// Increments the daily scan count.
  ///
  /// This should be called after a successful scan.
  static Future<void> incrementScanCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateString();
    
    // Ensure the date is current before incrementing
    final lastScanDate = prefs.getString(_lastScanDateKey);
    int currentCount = prefs.getInt(_scanCountKey) ?? 0;
    if (lastScanDate != today) {
        currentCount = 0;
        await prefs.setString(_lastScanDateKey, today);
    }

    await prefs.setInt(_scanCountKey, currentCount + 1);
  }

  /// Gets the current date as a string in 'YYYY-MM-DD' format.
  static String _getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// A helper to get the remaining scans for display purposes.
  static Future<int> getRemainingScans() async {
     final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateString();

    final lastScanDate = prefs.getString(_lastScanDateKey);
    int currentCount = prefs.getInt(_scanCountKey) ?? 0;

    if (lastScanDate != today) {
      currentCount = 0;
    }
    
    final remaining = _scanLimit - currentCount;
    return remaining > 0 ? remaining : 0;
  }
}