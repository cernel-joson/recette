import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/features/recipes/recipes.dart';
import 'package:recette/core/jobs/data/models/job_model.dart';
import 'package:recette/core/jobs/presentation/controllers/job_controller.dart';
import 'package:recette/core/jobs/data/repositories/job_repository.dart';

class RecipeLibraryScreen extends StatefulWidget {
  const RecipeLibraryScreen({
    super.key,
    this.isSelecting = false,
  });
  
  final bool isSelecting;

  @override
  State<RecipeLibraryScreen> createState() => _RecipeLibraryScreenState();
}

class _RecipeLibraryScreenState extends State<RecipeLibraryScreen> {
  final _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load data when the widget is first created.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecipeLibraryController>(context, listen: false).loadItems();
    });
  }
  
  void _reviewPendingJob(BuildContext context, Job job) async {
    final recipeMap = json.decode(job.responsePayload!) as Map<String, dynamic>;
    final recipe = Recipe.fromMap(recipeMap);
    
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => RecipeEditScreen(
          recipe: recipe,
          sourceJobId: job.id,
        ),
      ),
    );

    if (result == true && mounted) {
      Provider.of<RecipeLibraryController>(context, listen: false).loadItems();
    }
  }

  Future<void> _dismissJob(BuildContext context, Job job) async {
    final jobRepo = JobRepository();
    await jobRepo.updateJobStatus(job.id!, JobStatus.archived);
    if (mounted) {
      Provider.of<JobController>(context, listen: false).loadJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryController = context.watch<RecipeLibraryController>();
    final jobController = context.watch<JobController>();
            
    final pendingNewRecipeJobs = jobController.jobs.where((job) {
      final isCompletedRecipeJob =
          (job.jobType == 'recipe_analysis' || job.jobType == 'meal_suggestion') &&
          job.status == JobStatus.complete;
      if (!isCompletedRecipeJob) return false;
      if (job.jobType == 'recipe_analysis') {
        final requestData = json.decode(job.requestPayload);
        final recipeData = requestData['recipe_data'] as Map<String, dynamic>;
        return recipeData.containsKey('url') ||
               recipeData.containsKey('text') ||
               recipeData.containsKey('image');
      }
      return true;
    }).toList();
        
    if (libraryController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search (e.g., chicken tag:dinner)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: EdgeInsets.zero,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    libraryController.search('');
                  },
                ),
              ),
              onSubmitted: (query) => libraryController.search(query),
            ),
          ),
        ),
        ...pendingNewRecipeJobs.map((job) => PendingJobBanner(
              job: job,
              onView: () => _reviewPendingJob(context, job),
              onDismiss: () => _dismissJob(context, job),
            )),
        if (libraryController.recipes.isEmpty && pendingNewRecipeJobs.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No recipes found.'),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: libraryController.recipes.length,
              itemBuilder: (context, index) {
                final recipe = libraryController.recipes[index];
                return RecipeCard(
                  recipe: recipe,
                  onTap: () async {
                    if (widget.isSelecting) {
                      Navigator.of(context).pop(recipe.id);
                      return;
                    }
                    final dynamic result = await Navigator.push<dynamic>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeViewScreen(recipeId: recipe.id!),
                      ),
                    );
                    if (result is String) {
                      libraryController.setNavigationOrigin(recipe.id!);
                      libraryController.search(result);
                    } else if (result == true) {
                      libraryController.clearNavigationOrigin();
                      libraryController.loadItems();
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}