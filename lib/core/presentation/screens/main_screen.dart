import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/core/presentation/screens/about_screen.dart';
import 'package:recette/core/presentation/screens/jobs_tray_screen.dart';
import 'package:recette/core/presentation/screens/settings_screen.dart';
import 'package:recette/core/presentation/widgets/jobs_tray_icon.dart';
import 'package:recette/core/data/services/share_intent_service.dart';
import 'package:recette/core/presentation/utils/dialog_utils.dart';
import 'package:recette/features/dietary_profile/presentation/screens/dietary_profile_screen.dart';
import 'package:recette/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:recette/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:recette/features/meal_plan/presentation/controllers/meal_plan_controller.dart';
import 'package:recette/features/meal_plan/presentation/screens/meal_plan_screen.dart';
import 'package:recette/features/recipes/presentation/controllers/recipe_library_controller.dart';
import 'package:recette/features/recipes/presentation/screens/recipe_library_screen.dart';
import 'package:recette/features/recipes/presentation/utils/dialog_utils.dart' as recipe_dialog_utils;
import 'package:recette/features/shopping_list/presentation/controllers/shopping_list_controller.dart';
import 'package:recette/features/shopping_list/presentation/screens/shopping_list_screen.dart';
import 'package:recette/features/recipes/data/services/export_service.dart' as recipe_export_service;
import 'package:recette/features/recipes/data/services/import_service.dart' as recipe_import_service;
import 'package:recette/features/recipes/presentation/widgets/filter_bottom_sheet.dart';
import 'package:recette/core/presentation/screens/dashboard_screen.dart';

class NavDestination {
  final String label;
  final IconData icon;
  final Widget screen;

  const NavDestination(this.label, this.icon, this.screen);
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController;

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
    ShareIntentService.instance.init(GlobalKey<NavigatorState>());
  }

  @override
  void dispose() {
    _pageController.dispose();
    ShareIntentService.instance.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onMenuSelected(String value) async {
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
      case 'import_recipes':
        await recipe_import_service.ImportService.importLibrary();
        break;
      case 'export_recipes':
        await recipe_export_service.ExportService.exportLibrary();
        break;
    }
  }

  List<Widget> _buildContextualActions() {
    switch (_selectedIndex) {
      case 1: // Recipe Library
        return [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filters',
            onPressed: () async {
              final controller = context.read<RecipeLibraryController>();
              final String? constructedQuery = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const FilterBottomSheet(),
              );
              if (constructedQuery != null) {
                controller.search(constructedQuery);
              }
            },
          ),
        ];
      case 3: // Meal Planner
        return [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear Plan',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Meal Plan?'),
                  content: const Text('Are you sure you want to delete all entries?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Clear'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
                  ],
                ),
              );
              if (confirm == true) {
                await context.read<MealPlanController>().clearPlan();
              }
            },
          ),
        ];
      default:
        return [];
    }
  }

  Widget? _buildContextualFab() {
    switch (_selectedIndex) {
      case 1: // Recipe Library
        return FloatingActionButton(
          heroTag: 'addRecipeFab',
          onPressed: () => recipe_dialog_utils.DialogUtils.showAddRecipeMenu(context),
          tooltip: 'Add Recipe',
          child: const Icon(Icons.add),
        );
      case 2: // Inventory
        final controller = context.watch<InventoryController>();
        final isVisualTab = controller.tabIndex == 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (isVisualTab)
              FloatingActionButton(
                heroTag: 'addInventoryItemFab',
                onPressed: () => DialogUtils.showItemEditDialog(
                  context: context,
                  controller: controller,
                ),
                tooltip: 'Add Item',
                child: const Icon(Icons.add),
              ),
            const SizedBox(width: 8),
            FloatingActionButton.extended(
              heroTag: 'mealIdeasFab',
              onPressed: () => controller.getMealIdeas(context),
              tooltip: 'Get Meal Ideas',
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('What can I make?'),
            ),
          ],
        );
      case 4: // Shopping List
        final controller = context.watch<ShoppingListController>();
        final isVisualTab = controller.tabIndex == 0;
        if (!isVisualTab) return null; // No FAB on the Markdown tab
        return FloatingActionButton(
          heroTag: 'addShoppingItemFab',
          onPressed: () => DialogUtils.showItemEditDialog(
            context: context,
            controller: controller,
          ),
          tooltip: 'Add Item',
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_destinations[_selectedIndex].label),
        actions: [
          ..._buildContextualActions(),
          JobsTrayIcon(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JobsTrayScreen())),
          ),
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (BuildContext context) {
              final items = <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'profile', child: ListTile(leading: Icon(Icons.person_outline), title: Text('My Profile'))),
                const PopupMenuItem<String>(value: 'settings', child: ListTile(leading: Icon(Icons.settings_outlined), title: Text('Settings'))),
                const PopupMenuItem<String>(value: 'about', child: ListTile(leading: Icon(Icons.info_outline), title: Text('About'))),
              ];
              if (_selectedIndex == 1) {
                items.add(const PopupMenuDivider());
                items.add(const PopupMenuItem<String>(value: 'import_recipes', child: ListTile(leading: Icon(Icons.download), title: Text('Import Library'))));
                items.add(const PopupMenuItem<String>(value: 'export_recipes', child: ListTile(leading: Icon(Icons.upload_file), title: Text('Export Library'))));
              }
              return items;
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _destinations.map((d) => d.screen).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _destinations.map((destination) {
          return BottomNavigationBarItem(icon: Icon(destination.icon), label: destination.label);
        }).toList(),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButton: _buildContextualFab(),
    );
  }
}