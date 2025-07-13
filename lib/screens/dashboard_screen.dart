// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import 'recipe_library_screen.dart';

/// The main landing screen of the app, serving as a visual menu.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intelligent Nutrition'),
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
            const SizedBox(height: 8),
            DashboardCard(
              icon: Icons.calendar_month_outlined,
              title: 'Meal Planner',
              subtitle: 'Plan your meals for the week ahead',
              onTap: () {
                // Placeholder for future feature
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Meal Planner coming soon!')),
                );
              },
            ),
            const SizedBox(height: 8),
            DashboardCard(
              icon: Icons.calendar_month_outlined,
              title: 'Shopping Lists',
              subtitle: 'Create shopping lists for your meals',
              onTap: () {
                // Placeholder for future feature
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shopping Lists coming soon!')),
                );
              },
            ),
            // You can add more cards here for future features.
          ],
        ),
      ),
    );
  }
}