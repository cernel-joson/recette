import 'package:flutter/material.dart';
import 'package:recette/features/recipes/services/services.dart';

class RecipeAnalysisDialog extends StatefulWidget {
  const RecipeAnalysisDialog({super.key});

  @override
  State<RecipeAnalysisDialog> createState() => _RecipeAnalysisDialogState();
}

class _RecipeAnalysisDialogState extends State<RecipeAnalysisDialog> {
  final Set<RecipeAnalysisTask> _selectedTasks = {};

  void _onTaskSelected(bool? isSelected, RecipeAnalysisTask task) {
    setState(() {
      if (isSelected == true) {
        _selectedTasks.add(task);
      } else {
        _selectedTasks.remove(task);
      }
    });
  }

  void _submit() {
    Navigator.of(context).pop(_selectedTasks);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Run Recipe Analysis'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            title: const Text('Generate Tags'),
            subtitle: const Text('Create a new set of relevant tags.'),
            value: _selectedTasks.contains(RecipeAnalysisTask.generateTags),
            onChanged: (isSelected) => _onTaskSelected(isSelected, RecipeAnalysisTask.generateTags),
          ),
          CheckboxListTile(
            title: const Text('Perform Health Check'),
            subtitle: const Text('Analyze against your dietary profile.'),
            value: _selectedTasks.contains(RecipeAnalysisTask.healthCheck),
            onChanged: (isSelected) => _onTaskSelected(isSelected, RecipeAnalysisTask.healthCheck),
          ),
          CheckboxListTile(
            title: const Text('Estimate Nutrition'),
            subtitle: const Text('Calculate nutritional info per serving.'),
            value: _selectedTasks.contains(RecipeAnalysisTask.estimateNutrition),
            onChanged: (isSelected) => _onTaskSelected(isSelected, RecipeAnalysisTask.estimateNutrition),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedTasks.isEmpty ? null : _submit,
          child: const Text('Run Tasks'),
        ),
      ],
    );
  }
}