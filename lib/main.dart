import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:recette/core/jobs/job_controller.dart';
import 'package:recette/core/jobs/job_manager.dart';
import 'package:recette/core/jobs/job_repository.dart';
import 'package:recette/core/jobs/job_worker.dart';
import 'package:recette/features/recipes/data/jobs/recipe_parsing_worker.dart';
import 'firebase_options.dart'; // Import the generated file
import 'package:recette/core/presentation/screens/dashboard_screen.dart';

// Create a GlobalKey for the Navigator. This allows us to navigate
// from anywhere in the app, which is essential for the share handler.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // We no longer use dotenv for release builds, but it's needed for debug.
  // This will be handled by the launch.json configuration.
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  // --- NEW: Set up all job system dependencies ---
  final jobRepository = JobRepository();
  final jobController = JobController(jobRepository: jobRepository);
  final Map<String, JobWorker> workers = {
    'recipe_parsing': RecipeParsingWorker(),
    // Add other workers here as they are created
  };
  final jobManager = JobManager(
    jobRepository: jobRepository,
    jobController: jobController,
    workers: workers,
  );
  // --- END NEW SETUP ---

  runApp(
    // Use MultiProvider to provide both the controller and the manager
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: jobController),
        Provider.value(value: jobManager),
      ],
      child: const RecetteApp(),
    ),
  );
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