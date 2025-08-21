import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:recette/features/recipes/presentation/controllers/controllers.dart';
import 'package:recette/features/recipes/data/models/models.dart';
import 'package:recette/features/recipes/presentation/screens/recipe_edit_screen.dart';
import 'package:recette/features/recipes/data/services/ai_enhancement_service.dart';
import 'package:recette/features/recipes/data/services/recipe_import_service.dart';

class DialogUtils {
  /// Shows a modal bottom sheet with options for adding a new recipe.
  /// This method is now the orchestrator, calling the import service.
  static void showAddRecipeMenu(BuildContext context) {
    final importService = Provider.of<RecipeImportService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Import from Web (URL)'),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  final url = await _showUrlImportDialog(context);
                  if (url != null && context.mounted) {
                    _showSnackbar(context, 'URL import started...');
                    importService.importFromUrl(url).catchError((e) => _showErrorSnackbar(context, e));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.paste),
                title: const Text('Paste Recipe Text'),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  final text = await _showPasteTextDialog(context);
                  if (text != null && context.mounted) {
                    _showSnackbar(context, 'Text parsing started...');
                    importService.importFromText(text).catchError((e) => _showErrorSnackbar(context, e));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Enter Manually'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _navigateToEditScreen(context, null);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Scan from Camera'),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  final image = await _handleImagePicker(ImageSource.camera);
                  if (image != null && context.mounted) {
                    _showSnackbar(context, 'Image scan started...');
                    importService.importFromImage(image.path).catchError((e) => _showErrorSnackbar(context, e));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Scan from Gallery'),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                   final image = await _handleImagePicker(ImageSource.gallery);
                  if (image != null && context.mounted) {
                    _showSnackbar(context, 'Image scan started...');
                    importService.importFromImage(image.path).catchError((e) => _showErrorSnackbar(context, e));
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.analytics_outlined, color: Colors.blue),
                title: const Text('Quick Nutritional Analysis'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showNutritionDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// REFACTORED: Now a simple UI helper that returns the user's input.
  static Future<String?> _showUrlImportDialog(BuildContext context) {
    final urlController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import from Web'),
        content: TextField(
          controller: urlController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Paste Recipe URL'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(urlController.text), child: const Text('Import')),
        ],
      ),
    );
  }

  /// REFACTORED: Now a simple UI helper that returns the user's input.
  static Future<String?> _showPasteTextDialog(BuildContext context) {
    final textController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Parse Recipe from Text'),
        content: TextField(
          controller: textController,
          maxLines: 10,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Paste your recipe text here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(textController.text), child: const Text('Parse')),
        ],
      ),
    );
  }

  /// REFACTORED: Now a simple UI helper that returns the selected image file.
  static Future<XFile?> _handleImagePicker(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    return image;
  }

  // --- Helper methods for UI feedback ---
  static void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message Track progress in the Jobs Tray.'), backgroundColor: Colors.blue),
    );
  }

  static void _showErrorSnackbar(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${error.toString()}'), backgroundColor: Colors.red),
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

  // Navigation logic also stays here.
  static Future<void> _navigateToEditScreen(BuildContext context, Recipe? recipe,
      {bool showPasteDialog = false}) async {
    final controller = Provider.of<RecipeLibraryController>(context, listen: false);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeEditScreen(
          recipe: recipe,
        ),
      ),
    );

    // If a change happened on the edit screen, tell the controller to reload.
    if (result == true) {
      controller.loadInitialRecipes();
    }
  }
}