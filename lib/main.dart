import 'package:flutter/material.dart';
import 'package:recette/core/presentation/screens/dashboard_screen.dart';

// Create a GlobalKey for the Navigator. This allows us to navigate
// from anywhere in the app, which is essential for the share handler.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() {
  // Ensure that Flutter bindings are initialized before using plugins.
  WidgetsFlutterBinding.ensureInitialized();
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