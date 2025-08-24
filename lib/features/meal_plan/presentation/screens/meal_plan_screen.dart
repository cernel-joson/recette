import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/features/meal_plan/presentation/controllers/meal_plan_controller.dart';
import 'package:recette/features/recipes/presentation/screens/recipe_library_screen.dart';
// import 'package:table_calendar/table_calendar.dart'; // Temporarily removed for debugging
import 'package:recette/features/meal_plan/meal_plan.dart';

class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MealPlanController(),
      child: const _MealPlanView(),
    );
  }
}

class _MealPlanView extends StatefulWidget {
  const _MealPlanView();

  @override
  State<_MealPlanView> createState() => _MealPlanViewState();
}

class _MealPlanViewState extends State<_MealPlanView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<MealPlanController>(context, listen: false);
      // Load a week's worth of data initially
      final today = DateTime.now();
      controller.loadMealPlan(
          today.subtract(const Duration(days: 3)), today.add(const Duration(days: 3)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MealPlanController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Meal Plan'),
          ),
          body: Column(
            children: [
              // --- Simplified Date Navigation ---
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () {
                        final newDate = controller.focusedDate.subtract(const Duration(days: 1));
                        controller.setFocusedDate(newDate);
                      },
                    ),
                    Text(
                      "${controller.focusedDate.year}-${controller.focusedDate.month.toString().padLeft(2, '0')}-${controller.focusedDate.day.toString().padLeft(2, '0')}",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () {
                        final newDate = controller.focusedDate.add(const Duration(days: 1));
                        controller.setFocusedDate(newDate);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              // --- End of Simplified Navigation ---
              Expanded(
                child: _buildMealList(controller),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddMealDialog(context, controller),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildMealList(MealPlanController controller) {
    final dateKey =
        "${controller.focusedDate.year}-${controller.focusedDate.month.toString().padLeft(2, '0')}-${controller.focusedDate.day.toString().padLeft(2, '0')}";
    final entries = controller.mealPlan[dateKey] ?? [];

    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (entries.isEmpty) {
      return const Center(child: Text('No meals planned for this day.'));
    }

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ListTile(
          title: Text(entry.recipeTitle ?? entry.textEntry ?? 'Unknown'),
          subtitle: Text(entry.mealType),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => controller.deleteEntry(entry.id!),
          ),
        );
      },
    );
  }

  void _showAddMealDialog(
      BuildContext context, MealPlanController controller) {
    showDialog(
      context: context,
      builder: (context) {
        String mealType = 'Breakfast';
        final textController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Meal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: mealType,
                items: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    mealType = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Meal Description',
                  hintText: 'e.g., Leftover Pizza',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final recipeId = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const RecipeLibraryScreen(isSelecting: true),
                    ),
                  );
                  if (recipeId != null) {
                    final newEntry = MealPlanEntry(
                      date:
                          "${controller.focusedDate.year}-${controller.focusedDate.month.toString().padLeft(2, '0')}-${controller.focusedDate.day.toString().padLeft(2, '0')}",
                      mealType: mealType,
                      entryType: MealPlanEntryType.recipe,
                      recipeId: recipeId,
                    );
                    controller.addEntry(newEntry);
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Select from Recipe Library'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  final newEntry = MealPlanEntry(
                    date:
                        "${controller.focusedDate.year}-${controller.focusedDate.month.toString().padLeft(2, '0')}-${controller.focusedDate.day.toString().padLeft(2, '0')}",
                    mealType: mealType,
                    entryType: MealPlanEntryType.text,
                    textEntry: textController.text,
                  );
                  controller.addEntry(newEntry);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}