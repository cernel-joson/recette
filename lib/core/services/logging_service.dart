// lib/core/services/logging_service.dart

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class LoggingService {
  static void logError(dynamic error, StackTrace stackTrace) {
    // In debug mode, print to the console for immediate feedback.
    if (kDebugMode) {
      debugPrint('Caught error: $error');
      debugPrint(stackTrace.toString());
    }
    // In all modes (debug and release), send the error to Crashlytics.
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  static void logInfo(String message) {
    // You can also log non-fatal, informational messages.
    FirebaseCrashlytics.instance.log(message);
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}