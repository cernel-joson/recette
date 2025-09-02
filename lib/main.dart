import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:recette/core/jobs/presentation/controllers/job_controller.dart';
import 'package:recette/core/jobs/logic/job_manager.dart';
import 'package:recette/core/jobs/data/repositories/job_repository.dart';
import 'package:recette/core/jobs/logic/job_worker.dart';
import 'package:recette/core/utils/usage_limiter.dart';
import 'package:recette/features/recipes/data/jobs/recipe_analysis_worker.dart';
import 'package:recette/features/recipes/data/services/recipe_service.dart';
import 'package:recette/features/recipes/data/services/recipe_import_service.dart';
import 'firebase_options.dart'; // Import the generated file
import 'package:recette/core/data/services/developer_service.dart';
import 'package:recette/features/dietary_profile/data/jobs/profile_analysis_worker.dart';
import 'package:recette/features/inventory/data/jobs/inventory_import_worker.dart';
import 'package:recette/features/inventory/data/services/inventory_service.dart';
import 'package:recette/features/inventory/data/jobs/meal_suggestion_worker.dart';
import 'package:recette/core/presentation/screens/main_screen.dart';

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
  
  // --- REFACTORED: Set up all dependencies for providing ---
  final jobRepository = JobRepository();
  final jobController = JobController(jobRepository: jobRepository);
  final usageLimiter = await UsageLimiter.create();
  final Map<String, JobWorker> workers = {
    'recipe_analysis': RecipeAnalysisWorker(),
    'profile_review': ProfileAnalysisWorker(),
    'inventory_import': InventoryImportWorker(),
    'meal_suggestion': MealSuggestionWorker(),
  };
  
  workers.forEach((key, value) {
    JobManager.instance.registerWorker(key, value);
  });

  final jobManager = JobManager.instance;
  // Create an instance of the new developer service
  final developerService = DeveloperService();

  // Create instances of the new services
  final recipeService = RecipeService();
  final recipeImportService = RecipeImportService(jobManager, usageLimiter);
  final inventoryService = InventoryService();
  // --- END REFACTORED SETUP ---

  runApp(
    // Use MultiProvider to provide both the controller and the manager
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: jobController),
        ChangeNotifierProvider.value(value: developerService), // Provide the new service
        // Provide all the core services to the widget tree
        Provider.value(value: jobManager),
        Provider.value(value: recipeService),
        Provider.value(value: recipeImportService),
        Provider.value(value: inventoryService),
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
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}