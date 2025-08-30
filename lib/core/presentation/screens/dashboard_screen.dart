import 'dart:async';
import 'package:flutter/material.dart';
import 'package:recette/features/recipes/recipes.dart';

/// The main landing screen of the app, serving as a visual menu.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final RecipeService _recipeService = RecipeService();
  late Future<List<Recipe>> _recentRecipesFuture;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() {
    setState(() {
      _recentRecipesFuture = _recipeService.getRecentRecipes(limit: 5);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Recipe>>(
        future: _recentRecipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No recent recipes found.'));
          }

          final recentRecipes = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              _buildGreetingCard(),
              const SizedBox(height: 16),
              _buildRecentlyAddedSection(context, recentRecipes),
            ],
          );
        },
      ),
    );
  }

  /// A simple card that displays a time-based greeting.
  Widget _buildGreetingCard() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning!';
    } else if (hour < 17) {
      greeting = 'Good afternoon!';
    } else {
      greeting = 'Good evening!';
    }
    return Card(
      child: ListTile(
        leading: const Icon(Icons.wb_sunny_outlined),
        title: Text(greeting),
        subtitle: const Text('What are we cooking today?'),
      ),
    );
  }

  /// A section to display a horizontally-scrolling list of recent recipes.
  Widget _buildRecentlyAddedSection(BuildContext context, List<Recipe> recipes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Recently Added',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200, // Constrain the height of the horizontal list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return SizedBox(
                width: 300, // Give each card a fixed width
                child: RecipeCard(
                  recipe: recipe,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RecipeViewScreen(recipeId: recipe.id!),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
