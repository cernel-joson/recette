// lib/screens/dashboard_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:recette/features/recipes/recipes.dart';
import 'package:recette/core/core.dart';
import 'package:recette/main.dart'; // Import main.dart to get access to the navigatorKey
import 'package:recette/features/dietary_profile/presentation/screens/screens.dart'; // Import the new screen
import 'package:recette/features/inventory/presentation/screens/screens.dart'; // Add this import
import 'package:recette/features/shopping_list/presentation/screens/screens.dart';
import 'package:recette/features/meal_plan/presentation/screens/screens.dart';
import 'package:recette/core/presentation/screens/about_screen.dart';
import 'package:recette/core/services/developer_service.dart';
import 'package:provider/provider.dart';
import 'package:recette/core/presentation/widgets/jobs_tray_icon.dart';

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

  // --- REFACTORED: This method now uses the job system ---
  void _handleSharedIntent(SharedMediaFile file) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final importService = Provider.of<RecipeImportService>(context, listen: false);

    // Show a confirmation snackbar immediately
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shared content received! Parsing in the background...'),
        backgroundColor: Colors.blue,
      ),
    );

    // Use the import service to submit the job asynchronously
    try {
      if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
        importService.importFromUrl(file.path);
      } else if (file.type == SharedMediaType.image) {
        importService.importFromImage(file.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for changes in DeveloperService
    final devService = context.watch<DeveloperService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recette'),
        actions: [
          const JobsTrayIcon(),
        ],
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
            DashboardCard(
              icon: Icons.info_outline,
              title: 'About Recette',
              subtitle: 'App version and information',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
            // --- Conditionally render the Developer Options card ---
            if (devService.isDeveloperMode) ...[
              const SizedBox(height: 8),
              DashboardCard(
                icon: Icons.developer_mode,
                title: 'Developer Options',
                subtitle: 'Debugging tools and feature flags',
                onTap: () {
                  // TODO: Navigate to the Developer Options screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Developer screen not yet implemented.')),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
