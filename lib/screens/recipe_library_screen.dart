import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import '../models/recipe_model.dart';
import 'recipe_edit_screen.dart';
import 'recipe_view_screen.dart'; // Import the new view screen
import '../controllers/recipe_library_controller.dart';

class RecipeLibraryScreen extends StatelessWidget {
  const RecipeLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Create the provider at the top level of the screen.
    return ChangeNotifierProvider(
      create: (_) => RecipeLibraryController(),
      // 2. The actual UI is now built by a child widget that has
      //    access to the provider.
      child: const _RecipeLibraryView(),
    );
  }
}

class _RecipeLibraryView extends StatelessWidget {
  const _RecipeLibraryView();

  /// Shows a modal bottom sheet with options for adding a new recipe.
  /// This method now lives in the UI layer and takes context.
  void _showAddRecipeMenu(BuildContext context) {
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
            ],
          ),
        );
      },
    );
  }

  /// Shows a dialog for importing a recipe from a URL.
  void _showUrlImportDialog(BuildContext context) {
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
          builder: (context, setDialogState) {
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

                          try {
                            // 2. Call the CONTROLLER to do the work
                            final recipe = await controller.analyzeUrl(urlController.text);
                            
                            // 3. Handle success (UI logic)
                            Navigator.of(context).pop(); // Close the dialog
                            _navigateToEditScreen(context, recipe); // Navigate

                          } catch (e) {
                            // 4. Handle error (UI logic)
                            setDialogState(() {
                              errorMessage = e.toString();
                            });
                          } finally {
                            // 5. Always stop loading (UI logic)
                            setDialogState(() {
                              isLoading = false;
                            });
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
  Future<void> _handleOcrScan(BuildContext context, ImageSource source) async {
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
  Future<void> _navigateToEditScreen(BuildContext context, Recipe? recipe,
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
      controller.loadRecipes();
    }
  }

  @override
  Widget build(BuildContext context) {
    // The ChangeNotifierProvider creates the controller and makes it available
    // to all widgets below it in the tree.
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipe Library'),
      ),
      // The Consumer widget listens for notifications and rebuilds the UI
      body: Consumer<RecipeLibraryController>(
        builder:(context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (controller.recipes == null || controller.recipes!.isEmpty) {
            return const Center(
              child: Text('Your library is empty.\nTap the + button to add a new recipe.'),
            );
          }
          
          // Your existing ListView.builder logic goes here,
          // but it uses the controller's data.
          return ListView.builder(
            itemCount: controller.recipes!.length,
            itemBuilder: (context, index) {
              final recipe = controller.recipes![index];
              return Dismissible(
                key: Key(recipe.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  controller.deleteRecipe(recipe.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${recipe.title}" deleted')),
                  );
                },
                child: ListTile(
                  title: Text(recipe.title),
                  subtitle: Text(
                    recipe.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    // CORRECTED: Pass the recipe.id! to the RecipeViewScreen's recipeId parameter.
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeViewScreen(recipeId: recipe.id!),
                      ),
                    );
                    // If the view screen returns true, it means a change (edit or delete) occurred.
                    if (result == true) {
                      // After returning, tell the controller to refresh the data.
                      // We use the Consumer's context here.
                      Provider.of<RecipeLibraryController>(context, listen: false).loadRecipes();
                    }
                  },
                ),
              );
            },
          );
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecipeMenu(context), // Pass the build context here
        tooltip: 'Add Recipe',
        child: const Icon(Icons.add),
      ),
    );
  }
}


/*class RecipeLibraryScreen extends StatefulWidget {
  const RecipeLibraryScreen({super.key});

  @override
  State<RecipeLibraryScreen> createState() => _RecipeLibraryScreenState();
}

class _RecipeLibraryScreenState extends State<RecipeLibraryScreen> {
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipe Library'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecipeMenu,
        tooltip: 'Add Recipe',
        child: const Icon(Icons.add),
      ),
    );
  }
}*/