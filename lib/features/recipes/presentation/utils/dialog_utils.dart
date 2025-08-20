import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:recette/core/jobs/job_manager.dart';
import 'package:recette/features/recipes/presentation/controllers/controllers.dart';
import 'package:recette/features/recipes/data/models/models.dart';
import 'package:recette/features/recipes/presentation/screens/recipe_edit_screen.dart';
import 'package:recette/features/recipes/data/services/ai_enhancement_service.dart';

class DialogUtils {
  /// Shows a modal bottom sheet with options for adding a new recipe.
  /// This method now lives in the UI layer and takes context.
  static void showAddRecipeMenu(BuildContext context) {
    showModalBottomSheet( 
      context: context,
      // CORRECTED: The builder now uses a different name for its context (`bottomSheetContext`)
      // to avoid shadowing the main `context` that has the provider.
      builder: (BuildContext bottomSheetContext) { // We get a new context for the bottom sheet
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Import from Web (URL)'),
                onTap: () {
                  // Pop using the sheet's own context
                  Navigator.pop(bottomSheetContext);
                  // Show the dialog using the original, correct context from the screen
                  _showUrlImportDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.paste),
                title: const Text('Paste Recipe Text'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditScreen(context, null, showPasteDialog: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Enter Manually'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditScreen(context, null, showPasteDialog: false);
                },
              ),
              // Updated "Scan from Camera" option
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Scan from Camera'),
                onTap: () {
                  Navigator.pop(context); // Close the sheet
                  _handleOcrScan(context, ImageSource.camera); // Pass the main screen's context
                },
              ),
              // New "Scan from Gallery" option
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Scan from Gallery'),
                onTap: () {
                  Navigator.pop(context); // Close the sheet
                  _handleOcrScan(context, ImageSource.gallery); // Pass the main screen's context
                },
              ),
              const Divider(), // --- NEW ---
              ListTile( // --- NEW ---
                leading: const Icon(Icons.analytics_outlined, color: Colors.blue),
                title: const Text('Quick Nutritional Analysis'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showNutritionDialog(context); // Call our new dialog
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- NEW DIALOG FOR NUTRITIONAL ANALYSIS ---
  static void _showNutritionDialog(BuildContext context) {
    final textController = TextEditingController();
    bool isLoading = false;
    Map<String, dynamic>? nutritionData;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              title: const Text('Quick Nutritional Analysis'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Paste a recipe below to get an estimated nutritional breakdown per serving."),
                    const SizedBox(height: 16),
                    TextField(
                      controller: textController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        hintText: 'Paste your recipe text here...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (nutritionData != null) ...[
                      const Divider(height: 24),
                      Text('Estimated Nutrition:', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      // Display all the new, detailed fields
                      Text('• Calories: ${nutritionData!['calories'] ?? 'N/A'}'),
                      Text('• Protein: ${nutritionData!['protein_grams'] ?? 'N/A'} g'),
                      Text('• Carbohydrates: ${nutritionData!['carbohydrates_grams'] ?? 'N/A'} g'),
                      Text('• Sugar: ${nutritionData!['sugar_grams'] ?? 'N/A'} g'),
                      Text('• Fat: ${nutritionData!['fat_grams'] ?? 'N/A'} g'),
                      Text('• Saturated Fat: ${nutritionData!['saturated_fat_grams'] ?? 'N/A'} g'),
                      Text('• Fiber: ${nutritionData!['fiber_grams'] ?? 'N/A'} g'),
                      Text('• Sodium: ${nutritionData!['sodium_milligrams'] ?? 'N/A'} mg'),
                      Text('• Cholesterol: ${nutritionData!['cholesterol_milligrams'] ?? 'N/A'} mg'),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
                FilledButton(
                  onPressed: isLoading ? null : () async {
                    if (textController.text.isEmpty) return;
                    setDialogState(() {
                      isLoading = true;
                      nutritionData = null;
                    });
                    
                    try {
                      final service = AiEnhancementService();
                      final result = await service.getNutritionalAnalysisForText(textController.text);
                       setDialogState(() {
                        nutritionData = result;
                        isLoading = false;
                      });
                    } catch (e) {
                       setDialogState(() { isLoading = false; });
                       ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                       );
                    }
                  },
                  child: const Text('Analyze'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- REFACTORED to be asynchronous ---
  static _showUrlImportDialog(BuildContext context) {
    final controller = Provider.of<RecipeLibraryController>(context, listen: false);
    final jobManager = Provider.of<JobManager>(context, listen: false);
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Import from Web'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(labelText: 'Paste Recipe URL'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (urlController.text.isEmpty) return;
                
                // Pop the dialog immediately
                Navigator.of(dialogContext).pop();
                
                try {
                  // Submit the job and show a confirmation snackbar
                  await controller.analyzeUrl(urlController.text, jobManager);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recipe parsing started... Track progress in the Jobs Tray.'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }

  // --- REFACTORED to be asynchronous ---
  static Future<void> _handleOcrScan(BuildContext context, ImageSource source) async {
    final controller = Provider.of<RecipeLibraryController>(context, listen: false);
    final jobManager = Provider.of<JobManager>(context, listen: false);

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image == null || !context.mounted) return;

    try {
      // Submit the job and show a confirmation snackbar
      await controller.analyzeImageFromPath(image.path, jobManager);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image scan started... Track progress in the Jobs Tray.'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  // Navigation logic also stays here.
  static Future<void> _navigateToEditScreen(BuildContext context, Recipe? recipe,
      {bool showPasteDialog = false}) async {
    final controller = Provider.of<RecipeLibraryController>(context, listen: false);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeEditScreen(
          recipe: recipe,
          showPasteDialogOnLoad: showPasteDialog,
        ),
      ),
    );

    // If a change happened on the edit screen, tell the controller to reload.
    if (result == true) {
      controller.loadInitialRecipes();
    }
  }
}