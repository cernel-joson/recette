import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:recette/core/jobs/presentation/controllers/job_controller.dart';
import 'package:recette/core/jobs/logic/job_manager.dart';
import 'package:recette/core/jobs/data/repositories/job_repository.dart';
import 'package:recette/core/jobs/logic/job_worker.dart';
import 'package:recette/core/utils/usage_limiter.dart';
import 'package:recette/features/recipes/data/jobs/healthify_recipe_worker.dart';
import 'package:recette/features/recipes/data/jobs/recipe_analysis_worker.dart';
import 'package:recette/features/recipes/data/services/recipe_import_service.dart';
import 'firebase_options.dart';
import 'package:recette/core/data/services/developer_service.dart';
import 'package:recette/features/dietary_profile/data/jobs/profile_analysis_worker.dart';
import 'package:recette/features/inventory/data/jobs/inventory_import_worker.dart';
import 'package:recette/features/inventory/data/jobs/meal_suggestion_worker.dart';
import 'package:recette/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:recette/core/presentation/screens/main_screen.dart';
import 'package:recette/features/recipes/presentation/controllers/recipe_library_controller.dart';
import 'package:recette/features/shopping_list/presentation/controllers/shopping_list_controller.dart';
import 'package:recette/features/meal_plan/presentation/controllers/meal_plan_controller.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  final jobRepository = JobRepository();
  final jobController = JobController(jobRepository: jobRepository);
  final usageLimiter = await UsageLimiter.create();
  final Map<String, JobWorker> workers = {
    'recipe_analysis': RecipeAnalysisWorker(),
    'profile_review': ProfileAnalysisWorker(),
    'inventory_import': InventoryImportWorker(),
    'meal_suggestion': MealSuggestionWorker(),
    'healthify_recipe': HealthifyRecipeWorker(),
  };
  
  workers.forEach((key, value) {
    JobManager.instance.registerWorker(key, value);
  });

  final jobManager = JobManager.instance;
  final developerService = DeveloperService();
  final recipeImportService = RecipeImportService(jobManager, usageLimiter);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: jobController),
        ChangeNotifierProvider.value(value: developerService),
        Provider.value(value: jobManager),
        Provider.value(value: recipeImportService),
        
        // --- THIS IS THE FIX ---
        // All feature controllers are now correctly created and provided to the app.
        // This ensures that each screen can find its required controller.
        ChangeNotifierProvider(create: (_) => RecipeLibraryController()),
        ChangeNotifierProvider(create: (_) => InventoryController()),
        ChangeNotifierProvider(create: (_) => ShoppingListController()),
        ChangeNotifierProvider(create: (_) => MealPlanController()),
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
      navigatorKey: navigatorKey,
      title: 'Recette',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

