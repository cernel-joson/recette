import 'package:flutter/material.dart';
import 'package:recette/features/recipes/data/services/ai_enhancement_service.dart';

class AiEnhancementDialog extends StatefulWidget {
  const AiEnhancementDialog({super.key});

  @override
  State<AiEnhancementDialog> createState() => _AiEnhancementDialogState();
}

class _AiEnhancementDialogState extends State<AiEnhancementDialog> {
  // Use a Set to keep track of the selected tasks
  final Set<AiEnhancementTask> _selectedTasks = {};

  void _onTaskSelected(bool? isSelected, AiEnhancementTask task) {
    setState(() {
      if (isSelected == true) {
        _selectedTasks.add(task);
      } else {
        _selectedTasks.remove(task);
      }
    });
  }

  void _submit() {
    // Pop the dialog and return the set of selected tasks
    Navigator.of(context).pop(_selectedTasks);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI Recipe Analysis'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            title: const Text('Regenerate Tags'),
            subtitle: const Text('Create a new set of tags based on the recipe.'),
            value: _selectedTasks.contains(AiEnhancementTask.generateTags),
            onChanged: (isSelected) => _onTaskSelected(isSelected, AiEnhancementTask.generateTags),
          ),
          CheckboxListTile(
            title: const Text('Perform Health Check'),
            subtitle: const Text('Analyze against your dietary profile.'),
            value: _selectedTasks.contains(AiEnhancementTask.healthCheck),
            onChanged: (isSelected) => _onTaskSelected(isSelected, AiEnhancementTask.healthCheck),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Return null on cancel
          child: const Text('Cancel'),
        ),
        FilledButton(
          // Disable the button if no tasks are selected
          onPressed: _selectedTasks.isEmpty ? null : _submit,
          child: const Text('Analyze'),
        ),
      ],
    );
  }
}