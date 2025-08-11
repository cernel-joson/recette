// lib/screens/dashboard_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:recette/features/recipes/recipes.dart';
import 'package:recette/core/core.dart';
import 'package:recette/main.dart'; // Import main.dart to get access to the navigatorKey
import 'package:recette/features/dietary_profile/presentation/screens/dietary_profile_screen.dart'; // Import the new screen
import 'package:recette/features/inventory/presentation/screens/inventory_screen.dart'; // Add this import
import 'package:recette/features/shopping_list/presentation/screens/shopping_list_screen.dart';
import 'package:recette/features/meal_plan/presentation/screens/meal_plan_screen.dart';

/// The main landing screen of the app, serving as a visual menu.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // A stream subscription to listen for incoming share events.
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    // Start listening for share events when the screen is first created.
    _listenForSharedData();
  }

  @override
  void dispose() {
    // Cancel the subscription when the screen is disposed to prevent memory leaks.
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  /// Sets up listeners for handling shared data, both when the app is
  /// launched from a share and when it's already running.
  void _listenForSharedData() {
    // The modern API uses a single stream for all shared media.
    _intentDataStreamSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) _handleSharedIntent(value.first);
    }, onError: (err) {
      debugPrint("getMediaStream error: $err");
    });

    // Also check for media shared when the app was closed.
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) _handleSharedIntent(value.first);
    });
  }

  /// A unified handler for all incoming shared data.
  void _handleSharedIntent(SharedMediaFile file) {
    // Check the type of the shared file.
    if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
      // If it's text or a URL, analyze it as a URL.
      _analyzeAndNavigate(RecipeParsingService.analyzeUrl(file.path));
    } else if (file.type == SharedMediaType.image) {
      // If it's an image, analyze it as an image path.
      _analyzeAndNavigate(RecipeParsingService.analyzeImage(file.path));
    }
  }

  /// A generic function to show a loading indicator, call the API,
  /// and navigate to the edit screen.
  void _analyzeAndNavigate(Future<Recipe> analysisFuture) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Show a loading indicator via a SnackBar.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receiving and analyzing shared content...'),
        duration: Duration(seconds: 30),
      ),
    );

    analysisFuture.then((recipe) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeEditScreen(recipe: recipe),
        ),
      );
    }).catchError((e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Analysis Error'),
          content: Text('An error occurred: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recette'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            DashboardCard(
              icon: Icons.collections_bookmark_outlined,
              title: 'My Recipe Library',
              subtitle: 'View, add, and manage your saved recipes',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RecipeLibraryScreen()),
                );
              },
            ),
            // --- NEW INVENTORY CARD ---
            DashboardCard(
              icon: Icons.kitchen_outlined,
              title: 'My Inventory',
              subtitle: 'Track the food you have on hand',
              onTap: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const InventoryScreen()),
                );
              },
            ),
            // --- END NEW CARD ---
            const SizedBox(height: 8),
            // NEW: Add a card for the Dietary Profile
            DashboardCard(
              icon: Icons.person_outline,
              title: 'My Dietary Profile',
              subtitle: 'Set your health goals and preferences',
              onTap: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DietaryProfileScreen()),
                );
              },
            ),
            // ... After Dietary Profile Card
            const SizedBox(height: 8),
            DashboardCard(
              icon: Icons.calendar_month_outlined,
              title: 'Meal Planner',
              subtitle: 'Plan your meals for the week ahead',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MealPlanScreen()));
              },
            ),
            const SizedBox(height: 8),
            DashboardCard(
              icon: Icons.shopping_cart_outlined,
              title: 'Shopping List',
              subtitle: 'Create and manage your grocery lists',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ShoppingListScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
