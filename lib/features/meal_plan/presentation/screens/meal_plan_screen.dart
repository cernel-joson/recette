import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:recette/features/meal_plan/data/models/meal_plan_entry_model.dart';
import 'package:recette/features/meal_plan/presentation/controllers/meal_plan_controller.dart';
import 'package:recette/features/recipes/data/models/recipe_model.dart';
import 'package:recette/features/recipes/presentation/screens/recipe_library_screen.dart';
import 'package:recette/features/recipes/presentation/screens/recipe_view_screen.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  late final MealPlanController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MealPlanController();
    _controller.loadItems();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<MealPlanController>(
        builder: (context, controller, child) {
          return Scaffold(
            // The original Scaffold and its contents remain unchanged.
            appBar: AppBar(
              title: const Text('Meal Planner'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear Meal Plan?'),
                        content: const Text(
                            'Are you sure you want to delete all entries?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Clear'),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red)),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await controller.clearPlan();
                    }
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                _CalendarView(controller: controller),
                const Divider(height: 1.0),
                Expanded(
                  child: _EntryListView(controller: controller),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
// --- END OF FIX ---

// ... (_CalendarView and _EntryListView widgets are unchanged)
class _CalendarView extends StatelessWidget {
  final MealPlanController controller;
  const _CalendarView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: controller.selectedDate,
      selectedDayPredicate: (day) => isSameDay(controller.selectedDate, day),
      onDaySelected: (selectedDay, focusedDay) {
        controller.setSelectedDate(selectedDay);
      },
      eventLoader: (day) {
        return controller.groupedEntries[
                DateTime(day.year, day.month, day.day)] ??
            [];
      },
    );
  }
}

class _EntryListView extends StatelessWidget {
  final MealPlanController controller;
  const _EntryListView({required this.controller});

  Future<void> _addRecipe(
      BuildContext context, DateTime date, MealType mealType) async {
    final recipeId = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => const RecipeLibraryScreen(isSelecting: true),
      ),
    );

    if (recipeId != null) {
      // A more robust implementation would use a RecipeService here
      // This is a simplification for now.
      // final tempRecipe = Recipe(id: recipeId, title: 'Selected Recipe');
      // await controller.addRecipeToMealPlan(tempRecipe, date, mealType);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = controller.entriesForSelectedDate;
    final mealTypes = MealType.values;

    return ListView.builder(
      itemCount: mealTypes.length,
      itemBuilder: (context, index) {
        final mealType = mealTypes[index];
        final entriesForMeal =
            entries.where((e) => e.mealType == mealType).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                mealType.name[0].toUpperCase() + mealType.name.substring(1),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...entriesForMeal.map(
              (entry) => ListTile(
                title: Text(entry.recipeTitle),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => controller.deleteEntry(entry.id!),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeViewScreen(recipeId: entry.recipeId),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.green),
              title: Text('Add ${mealType.name}'),
              onTap: () =>
                  _addRecipe(context, controller.selectedDate, mealType),
            ),
            const Divider(),
          ],
        );
      },
    );
  }
}