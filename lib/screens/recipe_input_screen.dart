import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/recipe_model.dart';
import 'recipe_library_screen.dart';
import '../widgets/recipe_card.dart';

class RecipeInputScreen extends StatefulWidget {
  const RecipeInputScreen({super.key});

  @override
  State<RecipeInputScreen> createState() => _RecipeInputScreenState();
}

class _RecipeInputScreenState extends State<RecipeInputScreen> {
  final TextEditingController _urlController = TextEditingController();
  
  Recipe? _recipe;
  String? _errorMessage;
  bool _isLoading = false;

  final String _cloudFunctionUrl = "https://recipe-analyzer-api-1004204297555.us-central1.run.app";

  void _analyzeRecipe() async {
    final url = _urlController.text;
    if (url.isEmpty) {
      setState(() { _errorMessage = "Please enter a URL."; _recipe = null; });
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; _recipe = null; });

    try {
      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36',
        },
        body: json.encode({'url': url}),
      );

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          setState(() {
            _recipe = Recipe.fromJson(data, url);
            _errorMessage = null;
          });
        } on FormatException catch (e) {
          setState(() {
            _errorMessage = "Server returned a successful status, but the response was not valid JSON.\n\nError: $e\n\nResponse Body:\n${response.body}";
            _recipe = null;
          });
        }
      } else {
        String serverError;
        try {
           final Map<String, dynamic> errorData = json.decode(response.body);
           serverError = "Error ${response.statusCode}: ${errorData['error'] ?? response.body}";
        } on FormatException {
          serverError = "Server returned an unexpected error (Status ${response.statusCode}).\n\nResponse Body:\n${response.body}";
        }
        setState(() {
          _errorMessage = serverError;
          _recipe = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to connect to the server. Please check your internet connection.\n\nError: $e";
        _recipe = null;
      });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Widget _buildResultsArea() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.left)));
    if (_recipe != null) return RecipeCard(recipe: _recipe!);
    return const Center(child: Text("Analysis results will appear here...", style: TextStyle(fontSize: 16, color: Colors.grey)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Analyzer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.collections_bookmark_outlined),
            tooltip: 'My Library',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RecipeLibraryScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(controller: _urlController, decoration: const InputDecoration(labelText: 'Paste Recipe URL Here', border: OutlineInputBorder())),
            const SizedBox(height: 16.0),
            ElevatedButton(onPressed: _isLoading ? null : _analyzeRecipe, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16.0)), child: const Text('Analyze Recipe', style: TextStyle(fontSize: 16))),
            const SizedBox(height: 24.0),
            Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8.0)), child: _buildResultsArea())),
          ],
        ),
      ),
    );
  }
}