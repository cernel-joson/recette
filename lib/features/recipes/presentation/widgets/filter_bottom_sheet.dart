import 'package:flutter/material.dart';
import 'package:recette/features/recipes/data/repositories/recipe_repository.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final RecipeRepository _recipeRepository;

  _FilterBottomSheetState({
    RecipeRepository? recipeRepository,
  }) : _recipeRepository = recipeRepository ?? RecipeRepository();

  List<String> _allTags = [];
  Set<String> _selectedTags = {};
  final _includeController = TextEditingController();
  final _excludeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final tags = await _recipeRepository.getAllUniqueTags();
    if (mounted) {
      setState(() {
        _allTags = tags;
      });
    }
  }

  void _applyFilters() {
    // This is where we construct the canonical search string
    final List<String> queryParts = [];

    for (final tag in _selectedTags) {
      queryParts.add('tag:$tag');
    }

    if (_includeController.text.isNotEmpty) {
      queryParts.add('ingredient:${_includeController.text}');
    }

    if (_excludeController.text.isNotEmpty) {
      queryParts.add('-ingredient:${_excludeController.text}');
    }

    // Return the constructed query string to the previous screen
    Navigator.of(context).pop(queryParts.join(' '));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Filters', style: Theme.of(context).textTheme.headlineSmall),
          const Divider(),
          
          Text('Tags', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: _allTags.map((tag) {
              return FilterChip(
                label: Text(tag),
                selected: _selectedTags.contains(tag),
                onSelected: (isSelected) {
                  setState(() {
                    if (isSelected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          
          Text('Ingredients', style: Theme.of(context).textTheme.titleLarge),
          TextField(
            controller: _includeController,
            decoration: const InputDecoration(labelText: 'Contains Ingredient'),
          ),
          TextField(
            controller: _excludeController,
            decoration: const InputDecoration(labelText: 'Does NOT Contain Ingredient'),
          ),
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _applyFilters,
              child: const Text('Show Results'),
            ),
          ),
        ],
      ),
    );
  }
}