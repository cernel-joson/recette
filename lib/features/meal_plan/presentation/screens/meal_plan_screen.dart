// lib/features/meal_plan/presentation/screens/meal_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:recette/features/meal_plan/meal_plan.dart';
import 'package:recette/features/recipes/presentation/screens/recipe_library_screen.dart'; // To select recipes
import 'package:recette/core/presentation/widgets/jobs_tray_icon.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final _service = MealPlanService();
  late List<MealPlanDay> _weekPlan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeek();
  }

  void _loadWeek() async {
    setState(() { _isLoading = true; });
    final plan = await _service.getWeekPlan(DateTime.now());
    if (mounted) {
      setState(() {
        _weekPlan = plan;
        _isLoading = false;
      });
    }
  }

  void _selectRecipeForSlot(String date, String mealType) async {
    // Navigate to the library to pick a recipe.
    // The library screen will need a small modification to return a recipe ID.
    final int? selectedRecipeId = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecipeLibraryScreen(isSelecting: true)),
    );

    if (selectedRecipeId != null) {
      await _service.assignRecipeToSlot(date, mealType, selectedRecipeId);
      _loadWeek(); // Refresh the view
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plan'),
        actions: [
          const JobsTrayIcon(), // Add the new global icon
        ]
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _weekPlan.length,
              itemBuilder: (context, index) {
                final day = _weekPlan[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(day.date, style: Theme.of(context).textTheme.titleLarge),
                        _buildMealSlot(context, 'Breakfast', day.breakfastRecipeTitle, () => _selectRecipeForSlot(day.date, 'breakfast')),
                        _buildMealSlot(context, 'Lunch', day.lunchRecipeTitle, () => _selectRecipeForSlot(day.date, 'lunch')),
                        _buildMealSlot(context, 'Dinner', day.dinnerRecipeTitle, () => _selectRecipeForSlot(day.date, 'dinner')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMealSlot(BuildContext context, String title, String? recipeTitle, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      subtitle: Text(recipeTitle ?? 'Tap to select a recipe'),
      trailing: const Icon(Icons.add),
      onTap: onTap,
    );
  }
}