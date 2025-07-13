// lib/screens/recipe_library_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import '../helpers/api_helper.dart'; // Import the centralized helper
import '../helpers/database_helper.dart';
import '../helpers/usage_limiter.dart'; // Import the new helper
import '../models/recipe_model.dart';
import '../widgets/recipe_card.dart';
import 'recipe_edit_screen.dart';

/// A screen that displays a list of all recipes saved in the local database.
class RecipeLibraryScreen extends StatefulWidget {
  const RecipeLibraryScreen({super.key});

  @override
  State<RecipeLibraryScreen> createState() => _RecipeLibraryScreenState();
}

class _RecipeLibraryScreenState extends State<RecipeLibraryScreen> {
  List<Recipe>? _recipes;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final recipes = await DatabaseHelper.instance.getAllRecipes();
    if (mounted) {
      setState(() {
        _recipes = recipes;
      });
    }
  }

  Future<void> _deleteRecipe(int id) async {
    await DatabaseHelper.instance.delete(id);
    _loadRecipes();
  }

  Future<void> _navigateToEditScreen(BuildContext context, Recipe? recipe,
      {bool showPasteDialog = false}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeEditScreen(
          recipe: recipe,
          showPasteDialogOnLoad: showPasteDialog,
        ),
      ),
    );

    if (result == true) {
      _loadRecipes();
    }
  }

  void _showUrlImportDialog(BuildContext context) {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isLoading = false;
        String? errorMessage;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Import from Web'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'Paste Recipe URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (urlController.text.isEmpty) return;
                          setDialogState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                          try {
                            final recipe =
                                await ApiHelper.analyzeUrl(urlController.text);
                            if (mounted) {
                              Navigator.of(context).pop();
                              _navigateToEditScreen(context, recipe);
                            }
                          } catch (e) {
                            setDialogState(() {
                              errorMessage = e.toString();
                            });
                          } finally {
                            if (mounted) {
                              setDialogState(() {
                                isLoading = false;
                              });
                            }
                          }
                        },
                  child: const Text('Import'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// --- NEW: Handles the entire OCR flow ---
  Future<void> _handleOcrScan(ImageSource source) async {
    // Check usage limit first.
    final canScan = await UsageLimiter.canPerformScan();
    if (!canScan) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Daily Limit Reached'),
            content: const Text(
                'You have reached your daily limit for recipe scans. Please try again tomorrow.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Use ImagePicker to get an image.
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image == null) return; // User cancelled the picker.

    // Show a loading indicator.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Scanning and analyzing image...'),
            duration: Duration(seconds: 30)), // Long duration for analysis
      );
    }

    try {
      // Call the API helper to analyze the image.
      final recipe = await ApiHelper.analyzeImage(image);
      
      // Increment the scan count on success.
      await UsageLimiter.incrementScanCount();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _navigateToEditScreen(context, recipe);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Scan Error'),
            content: Text('An error occurred during the scan: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Shows a modal bottom sheet with options for adding a new recipe.
  void _showAddRecipeMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Import from Web (URL)'),
                onTap: () {
                  Navigator.pop(context);
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
                  Navigator.pop(context); // Close the sheet first
                  _handleOcrScan(ImageSource.camera);
                },
              ),
              // New "Scan from Gallery" option
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Scan from Gallery'),
                onTap: () {
                  Navigator.pop(context); // Close the sheet first
                  _handleOcrScan(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ... (The rest of the file, _buildBody and build methods, remains the same) ...
  Widget _buildBody() {
    if (_recipes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recipes!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Your library is empty.\nTap the + button to add a new recipe.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _recipes!.length,
      itemBuilder: (context, index) {
        final recipe = _recipes![index];
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
            _deleteRecipe(recipe.id!);
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
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: Text(recipe.title)),
                    body: RecipeCard(recipe: recipe),
                  ),
                ),
              );
              _loadRecipes();
            },
          ),
        );
      },
    );
  }

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
}