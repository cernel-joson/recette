import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intelligent_nutrition_app/features/recipes/data/models/models.dart';
import 'package:intelligent_nutrition_app/core/presentation/widgets/widgets.dart';

/// A widget that displays the contents of a recipe in a card-like format.
class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(recipe.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (recipe.sourceUrl.isNotEmpty &&
              recipe.sourceUrl.startsWith('http'))
            InkWell(
              onTap: () => launchUrl(Uri.parse(recipe.sourceUrl)),
              child: Text(
                'Source: ${recipe.sourceUrl}',
                style: TextStyle(
                    color: Colors.blue[800],
                    decoration: TextDecoration.underline),
              ),
            ),
          const SizedBox(height: 8),

          if (recipe.description.isNotEmpty)
            Text(recipe.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic, color: Colors.grey[700])),
          const SizedBox(height: 16),

          Wrap(
            spacing: 24.0,
            runSpacing: 8.0,
            children: [
              if (recipe.prepTime.isNotEmpty)
                InfoChip(
                    icon: Icons.timer_outlined,
                    label: "Prep: ${recipe.prepTime}"),
              if (recipe.cookTime.isNotEmpty)
                InfoChip(
                    icon: Icons.whatshot_outlined,
                    label: "Cook: ${recipe.cookTime}"),
              if (recipe.totalTime.isNotEmpty)
                InfoChip(
                    icon: Icons.access_time,
                    label: "Total: ${recipe.totalTime}"),
              if (recipe.servings.isNotEmpty)
                InfoChip(
                    icon: Icons.people_outline,
                    label: "Serves: ${recipe.servings}"),
              // New: Display other timings using the same InfoChip
              ...recipe.otherTimings.map(
                (timing) => InfoChip(
                  icon: Icons.hourglass_empty, // A generic icon for other times
                  label: "${timing.label}: ${timing.duration}",
                ),
              ),
            ],
          ),
          // --- NEW: Health Analysis Section ---
          if (recipe.healthRating != null && recipe.healthRating != 'UNRATED')
            Card(
              color: Colors.blueGrey[50],
              elevation: 0,
              child: ExpansionTile(
                leading: HealthRatingIcon(healthRating: recipe.healthRating),
                title: Text(
                  'Health Analysis',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(recipe.healthSummary ?? 'Tap to see suggestions.'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: recipe.healthSuggestions
                              ?.map((s) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text('• $s'),
                                  ))
                              .toList() ??
                          [],
                    ),
                  ),
                ],
              ),
            ),
          if (recipe.tags.isNotEmpty) ...[
            const Divider(height: 32.0),
            Text("Tags", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0, // gap between adjacent chips
              runSpacing: 4.0, // gap between lines
              // --- THIS IS THE CHANGE ---
              children: recipe.tags.map((tag) {
                return ActionChip(
                  label: Text(tag),
                  onPressed: () {
                    // When a tag is pressed, pop the current screen (RecipeViewScreen)
                    // and return a formatted search query as the result.
                    Navigator.of(context).pop('tag:$tag');
                  },
                );
              }).toList(),
            ),
          ],
          const Divider(height: 32.0),

          Text("Ingredients", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (var ingredient in recipe.ingredients)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text("• ${ingredient.toString()}",
                    style: Theme.of(context).textTheme.bodyLarge)),
          const Divider(height: 32.0),

          Text("Instructions", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recipe.instructions.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(recipe.instructions[index],
                    style: Theme.of(context).textTheme.bodyLarge),
              );
            },
          ),
        ],
      ),
    );
  }
}