// main.dart
// This file is the entry point for your Flutter application.

import 'package:flutter/material.dart';
import '../screens/recipe_input_screen.dart';

// --- Main App ---
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IntelligentNutritionApp());
}

class IntelligentNutritionApp extends StatelessWidget {
  const IntelligentNutritionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutrition App Prototype',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'NotoSans',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const RecipeInputScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
