import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/features/recipes/data/models/models.dart';
import 'package:recette/features/recipes/presentation/widgets/widgets.dart';
import 'package:recette/features/recipes/presentation/controllers/controllers.dart';
import 'package:recette/core/jobs/data/repositories/job_repository.dart';
import 'package:recette/core/jobs/presentation/controllers/job_controller.dart';
import 'package:recette/core/jobs/data/models/job_model.dart';

/// A screen for creating a new recipe or editing an existing one.
class RecipeEditScreen extends StatelessWidget {
  const RecipeEditScreen({
    super.key,
    this.recipe,
    this.parentRecipeId,
    this.sourceJobId,
  });

  final Recipe? recipe;
  final int? parentRecipeId;
  final int? sourceJobId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecipeEditController(
        recipe,
        parentRecipeId: parentRecipeId,
        sourceJobId: sourceJobId, // <-- Pass to controller
      ),
      child: const _RecipeEditView(),
    );
  }
}

/// The UI portion of the Recipe Edit Screen
class _RecipeEditView extends StatefulWidget {
  const _RecipeEditView();

  @override
  State<_RecipeEditView> createState() => _RecipeEditViewState();
}

class _RecipeEditViewState extends State<_RecipeEditView> {
  Future<void> _addIngredient(BuildContext context, RecipeEditController controller) async {
    final newIngredient = await showDialog<Ingredient>(
      context: context,
      builder: (context) => const IngredientEditDialog(),
    );
    if (newIngredient != null) {
      controller.addIngredient(newIngredient);
    }
  }

  Future<void> _editIngredient(BuildContext context, RecipeEditController controller, int index) async {
    final updatedIngredient = await showDialog<Ingredient>(
      context: context,
      builder: (context) => IngredientEditDialog(ingredient: controller.ingredients[index]),
    );
    if (updatedIngredient != null) {
      controller.editIngredient(index, updatedIngredient);
    }
  }

  Future<void> _editInstruction(BuildContext context, RecipeEditController controller, int index) async {
    final textController = TextEditingController(text: controller.instructions[index]);
    final updatedInstruction = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit Step ${index + 1}'),
        content: TextField(
          controller: textController,
          autofocus: true,
          maxLines: 5,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(textController.text), child: const Text('Save')),
        ],
      ),
    );
    if (updatedInstruction != null) {
      controller.editInstruction(index, updatedInstruction);
    }
  }
  
  Future<void> _addOtherTiming(BuildContext context, RecipeEditController controller) async {
    final newTiming = await showDialog<TimingInfo>(
      context: context,
      builder: (context) => const TimingInfoEditDialog(),
    );
    if (newTiming != null) {
      controller.addOtherTiming(newTiming);
    }
  }

  Future<void> _editOtherTiming(BuildContext context, RecipeEditController controller, int index) async {
    final updatedTiming = await showDialog<TimingInfo>(
      context: context,
      builder: (context) => TimingInfoEditDialog(timingInfo: controller.otherTimings[index]),
    );
    if (updatedTiming != null) {
      controller.editOtherTiming(index, updatedTiming);
    }
  }
  
  Future<bool> _showUnsavedChangesDialog(BuildContext context) async {
    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }
  
  // --- NEW: Method to show the duplicate recipe dialog ---
  Future<void> _showDuplicateRecipeDialog(BuildContext context, String message) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Duplicate Recipe'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Consumer rebuilds the widget tree when the controller calls notifyListeners().
    return Consumer<RecipeEditController>(
      builder: (context, controller, child) {
        return PopScope(
          canPop: !controller.isDirty,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            final shouldPop = await _showUnsavedChangesDialog(context);
            if (shouldPop && mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(controller.sourceUrl.isEmpty ? 'New Recipe' : 'Edit Recipe'),
            ),
            bottomNavigationBar: BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  /* TextButton.icon(
                    icon: controller.isAnalyzing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.paste_sharp),
                    label: const Text('Repopulate'),
                    onPressed: controller.isAnalyzing ? null : () => _showPasteTextDialog(context, controller),
                  ), */
                  // --- NEW: Conditionally add the Discard button ---
                  if (controller.sourceJobId != null)
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Discard'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () async {
                        final jobRepo = JobRepository();
                        await jobRepo.updateJobStatus(controller.sourceJobId!, JobStatus.archived);
                        if (mounted) {
                          Provider.of<JobController>(context, listen: false).loadJobs();
                          Navigator.of(context).pop(true); // Pop and trigger a refresh
                        }
                      },
                    ),
                  const Spacer(), // Pushes buttons to the right
                  // --- END OF NEW BUTTON ---
                  FilledButton.icon(
                    icon: const Icon(Icons.save),
                    // --- UPDATED: Save button logic ---
                    label: const Text('Save'),
                    onPressed: () async {
                      try {
                        // The saveForm method now handles archiving the job.
                        final success = await controller.saveForm();
                        if (success && mounted) {
                          // Refresh the job list so the banner disappears
                          Provider.of<JobController>(context, listen: false).loadJobs();
                          Navigator.of(context).pop(true);
                        }
                      } on RecipeExistsException catch (e) {
                        // If our specific exception is caught, show the dialog.
                        if (mounted) {
                          _showDuplicateRecipeDialog(context, e.message);
                        }
                      } catch (e) {
                        // Catch any other unexpected errors.
                        if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('An unexpected error occurred: $e')),
                          );
                        }
                      }
                    },
                    /*onPressed: () async {
                      try {
                        // Attempt to save the form.
                        await controller.saveForm();
                        // If successful, pop the screen.
                        if (mounted) {
                          Navigator.of(context).pop(true);
                        }
                      } on RecipeExistsException catch (e) {
                        // If our specific exception is caught, show the dialog.
                        if (mounted) {
                          _showDuplicateRecipeDialog(context, e.message);
                        }
                      } catch (e) {
                        // Catch any other unexpected errors.
                        if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('An unexpected error occurred: $e')),
                          );
                        }
                      }
                    },*/
                  ),
                ],
              ),
            ),
            body: Form(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(controller: controller.titleController, decoration: const InputDecoration(labelText: 'Title')),
                  const SizedBox(height: 16),
                  TextFormField(controller: controller.descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: TextFormField(controller: controller.prepTimeController, decoration: const InputDecoration(labelText: 'Prep Time'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(controller: controller.cookTimeController, decoration: const InputDecoration(labelText: 'Cook Time'))),
                  ]),
                  Row(children: [
                    Expanded(child: TextFormField(controller: controller.totalTimeController, decoration: const InputDecoration(labelText: 'Total Time'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(controller: controller.servingsController, decoration: const InputDecoration(labelText: 'Servings'))),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection(context, controller, 'Other Timings', controller.otherTimings, _addOtherTiming, _editOtherTiming, (ctrl, idx) => ctrl.removeOtherTiming(idx)),
                  // ... after the other sections ...
                  const SizedBox(height: 24),
                  
                  // --- Use your new custom widget ---
                  CustomChipInput(
                    initialChips: controller.tags,
                    onChipsChanged: (newTags) {
                      controller.updateTags(newTags);
                    },
                  ),
                  _buildSection(context, controller, 'Ingredients', controller.ingredients, _addIngredient, _editIngredient, (ctrl, idx) => ctrl.removeIngredient(idx)),
                  const SizedBox(height: 24),
                  _buildSection(context, controller, 'Instructions', controller.instructions, (ctx, ctrl) => ctrl.addInstruction(), _editInstruction, (ctrl, idx) => ctrl.removeInstruction(idx)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }// Generic builder for list sections to reduce code duplication
  Widget _buildSection<T>(
    BuildContext context,
    RecipeEditController controller,
    String title,
    List<T>? items,
    Function(BuildContext, RecipeEditController) onAdd,
    Function(BuildContext, RecipeEditController, int) onEdit,
    Function(RecipeEditController, int) onRemove,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (items != null)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: title == 'Instructions' ? Text('${index + 1}.') : null,
                title: Text(items[index].toString()),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => onRemove(controller, index),
                ),
                onTap: () => onEdit(context, controller, index),
              );
            },
          ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: Text('Add ${title.substring(0, title.length - 1)}'),
          onPressed: () => onAdd(context, controller),
        ),
      ],
    );
  }
}