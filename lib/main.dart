import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart'; // Import the generated file
import 'package:recette/core/presentation/screens/dashboard_screen.dart';

// Create a GlobalKey for the Navigator. This allows us to navigate
// from anywhere in the app, which is essential for the share handler.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  // Ensure that Flutter bindings are initialized before using plugins.
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Load the .env file
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- NEW CRASHLYTICS SETUP ---
  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  // --- END NEW SETUP ---
  
  runApp(const RecetteApp());
}

class RecetteApp extends StatelessWidget {
  const RecetteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Assign the navigatorKey to the MaterialApp.
      navigatorKey: navigatorKey,
      title: 'Recette',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Define a slightly elevated card theme for the dashboard
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
      // Set the DashboardScreen as the new home screen.
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}