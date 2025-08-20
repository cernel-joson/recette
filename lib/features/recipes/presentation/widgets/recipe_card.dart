// lib/features/recipes/presentation/widgets/recipe_card.dart

import 'package:flutter/material.dart';
import 'package:recette/features/recipes/recipes.dart';
import 'package:recette/core/presentation/widgets/health_rating_icon.dart';

/// A widget that displays a summary of a recipe for use in lists.
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      recipe.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  HealthRatingIcon(healthRating: recipe.healthRating),
                ],
              ),
              const SizedBox(height: 8),
              if (recipe.description.isNotEmpty)
                Text(
                  recipe.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (recipe.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children: recipe.tags.take(3).map((tag) => Chip(
                    label: Text(tag),
                    padding: EdgeInsets.zero,
                    labelStyle: Theme.of(context).textTheme.bodySmall,
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}