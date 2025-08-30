import 'package:flutter/material.dart';
import 'package:recette/core/presentation/screens/about_screen.dart';
import 'package:recette/core/presentation/screens/dashboard_screen.dart';
import 'package:recette/core/presentation/screens/jobs_tray_screen.dart';
import 'package:recette/core/presentation/screens/settings_screen.dart';
import 'package:recette/core/presentation/widgets/jobs_tray_icon.dart';
import 'package:recette/core/services/share_intent_service.dart';
import 'package:recette/features/dietary_profile/presentation/screens/dietary_profile_screen.dart';
import 'package:recette/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:recette/features/meal_plan/presentation/screens/meal_plan_screen.dart';
import 'package:recette/features/recipes/presentation/screens/recipe_library_screen.dart';
import 'package:recette/features/shopping_list/presentation/screens/shopping_list_screen.dart';

/// A data class to hold information for each navigation destination.
class NavDestination {
  final String label;
  final IconData icon;
  final Widget screen;

  const NavDestination(this.label, this.icon, this.screen);
}

/// The main screen of the app, which manages the bottom navigation bar and
/// the page view for the primary app features.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  // Define the primary navigation destinations. These will populate the
  // bottom navigation bar and the main page view.
  final List<NavDestination> _destinations = [
    const NavDestination('Home', Icons.home_outlined, DashboardScreen()),
    const NavDestination('Recipes', Icons.menu_book_outlined, RecipeLibraryScreen()),
    const NavDestination('Inventory', Icons.kitchen_outlined, InventoryScreen()),
    const NavDestination('Planner', Icons.calendar_today_outlined, MealPlanScreen()),
    const NavDestination('Shopping', Icons.shopping_cart_outlined, ShoppingListScreen()),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    // Initialize the share service when the main screen loads.
    ShareIntentService.instance.init(GlobalKey<NavigatorState>());
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Dispose the service to prevent memory leaks.
    ShareIntentService.instance.dispose();
    super.dispose();
  }

  /// Handles taps on the bottom navigation bar items.
  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Handles the selection from the overflow menu in the AppBar.
  void _onMenuSelected(String value) {
    switch (value) {
      case 'profile':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DietaryProfileScreen()));
        break;
      case 'settings':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
        break;
      case 'about':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // The title dynamically updates to match the current screen's label.
        title: Text(_destinations[_selectedIndex].label),
        actions: [
          // The global JobsTrayIcon remains in the top-right.
          JobsTrayIcon(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JobsTrayScreen())),
          ),
          // The overflow menu contains secondary navigation targets.
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: ListTile(leading: Icon(Icons.person_outline), title: Text('My Profile')),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: ListTile(leading: Icon(Icons.settings_outlined), title: Text('Settings')),
              ),
              const PopupMenuItem<String>(
                value: 'about',
                child: ListTile(leading: Icon(Icons.info_outline), title: Text('About')),
              ),
            ],
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        // Update the selected index when the user swipes between pages.
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _destinations.map((d) => d.screen).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        // Use the `map` function to create a list of BottomNavigationBarItem
        // widgets from our list of destinations.
        items: _destinations.map((destination) {
          return BottomNavigationBarItem(
            icon: Icon(destination.icon),
            label: destination.label,
          );
        }).toList(),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // This ensures all labels are always visible and the background is white.
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}