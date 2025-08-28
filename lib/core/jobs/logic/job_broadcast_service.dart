import 'package:flutter/foundation.dart';

/// A singleton service that acts as a central event bus for job-related changes.
///
/// It extends ChangeNotifier, so it can be listened to by UI controllers.
/// The JobRepository calls the public `broadcastJobDataChanged` method to
/// trigger a notification to all listeners.
class JobBroadcastService extends ChangeNotifier {
  // --- Singleton Implementation ---
  static final JobBroadcastService _instance = JobBroadcastService._internal();
  static JobBroadcastService get instance => _instance;
  JobBroadcastService._internal();

  /// A public method that any part of the system can call to signal
  /// that the underlying job data has been modified.
  void broadcastJobDataChanged() {
    // This call is now valid because it's happening inside an
    // instance member of a subclass of ChangeNotifier.
    notifyListeners();
  }
}