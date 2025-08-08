import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:provider/provider.dart';
import 'package:recette/features/recipes/presentation/controllers/controllers.dart';
import 'package:recette/features/recipes/data/models/models.dart';
import 'package:recette/features/recipes/presentation/screens/recipe_edit_screen.dart';
import 'package:recette/features/recipes/data/services/ai_enhancement_service.dart'; // Import the service

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

  /// Shows a dialog for importing a recipe from a URL.
  static _showUrlImportDialog(BuildContext context) {
    // Get the controller once, outside the builder.
    final controller = Provider.of<RecipeLibraryController>(context, listen: false);
    final urlController = TextEditingController();

    // --- State variables are declared OUTSIDE the builder ---
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing while loading
      builder: (dialogContext) {
        // StatefulBuilder allows the dialog to have its own internal state
        // without making the whole screen a StatefulWidget.
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              title: const Text('Import from Web'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(labelText: 'Paste Recipe URL'),
                    enabled: !isLoading,
                  ),
                  // The UI correctly reflects the 'isLoading' state
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (urlController.text.isEmpty) return;
                          
                          // 1. THIS is where isLoading is correctly set to true.
                          // Because it's outside the builder, this state change
                          // will persist when setDialogState rebuilds the dialog.
                          setDialogState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          Recipe? recipe;
                          String? error;

                          debugPrint('--- calling analyzeUrl() ---');
                          // 2. Call the CONTROLLER to do the work. Perform the async operation and store the result or error.
                          try {
                            recipe = await controller.analyzeUrl(urlController.text);
                          } catch (e) {
                            error = e.toString();
                          }
                          
                          // 3. Update the dialog's state with the outcome. This happens
                          //    BEFORE any navigation occurs.
                          setDialogState(() {
                            isLoading = false;
                            errorMessage = error;
                          });

                          // 4. Handle success (UI logic)
                          // Use the dialog's own context to pop it.
                          // If, and only if, the operation was successful,
                          //    pop the dialog and navigate.
                          if (recipe != null) {
                            // Pop the dialog using its own context.
                            if (Navigator.of(dialogContext).canPop()) {
                            debugPrint('--- calling pop() on dialogContext ---');
                              Navigator.of(dialogContext).pop(); // Close the dialog
                            }
                            debugPrint('--- calling _navigateToEditScreen() on context ---');
                            // Navigate using the main screen's context.
                            _navigateToEditScreen(context, recipe); // Navigate
                          }
                        },
                  child: const Text('Import'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  /// Handles the entire OCR flow
  /// This method also stays in the UI layer.
  static Future<void> _handleOcrScan(BuildContext context, ImageSource source) async {
    // Get the controller, but don't listen for changes here.
    final controller = Provider.of<RecipeLibraryController>(context, listen: false);

    // 1. Handle image picking (UI Logic)
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image == null) return; // User cancelled the picker.

    // 2. Show a loading indicator (UI Logic)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scanning and analyzing image...'),
        duration: Duration(seconds: 30) // Long duration for analysis
      ),
    );

    try {
      // 3. Call the CONTROLLER to perform the business logic
      final recipe = await controller.analyzeImageFromPath(image.path);

      // 4. Handle the result (UI Logic)
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      // Call the navigation method, which also stays in the UI layer.
      _navigateToEditScreen(context, recipe);

    } catch (e) {
      // 5. Handle any errors (UI Logic)
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Scan Error'),
          content: Text(e.toString()),
          actions: [ TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')) ],
        ),
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