// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart'; // Import the new dashboard screen

void main() {
  // Ensure that Flutter bindings are initialized before using plugins.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IntelligentNutritionApp());
}

class IntelligentNutritionApp extends StatelessWidget {
  const IntelligentNutritionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Intelligent Nutrition',
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