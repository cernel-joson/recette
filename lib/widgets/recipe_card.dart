import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required to load font assets
import 'package:url_launcher/url_launcher.dart';
// Import packages for PDF creation and printing.
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/recipe_model.dart';
import '../helpers/database_helper.dart';

import '../screens/recipe_edit_screen.dart';
import 'info_chip.dart';

// --- Recipe Card Widget ---

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  const RecipeCard({super.key, required this.recipe});

  Future<void> _launchSourceUrl() async {
    final Uri url = Uri.parse(recipe.sourceUrl);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, Recipe recipe) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    
    final fontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldFontData = await rootBundle.load("assets/fonts/NotoSans-Bold.ttf");
    final boldTtf = pw.Font.ttf(boldFontData);
    final italicFontData = await rootBundle.load("assets/fonts/NotoSans-Italic.ttf");
    final italicTtf = pw.Font.ttf(italicFontData);

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(recipe.title, style: pw.TextStyle(font: boldTtf, fontSize: 24)),
              pw.SizedBox(height: 8),
              if (recipe.sourceUrl.isNotEmpty)
                pw.UrlLink(destination: recipe.sourceUrl, child: pw.Text(recipe.sourceUrl, style: pw.TextStyle(font: ttf, color: PdfColors.blue, decoration: pw.TextDecoration.underline))),
              pw.SizedBox(height: 8),
              if (recipe.description.isNotEmpty)
                pw.Text(recipe.description, style: pw.TextStyle(font: italicTtf)),
              pw.SizedBox(height: 16),
              pw.Text('Ingredients', style: pw.TextStyle(font: boldTtf, fontSize: 18)),
              pw.SizedBox(height: 8),
              pw.ListView.builder(
                itemCount: recipe.ingredients.length,
                itemBuilder: (pw.Context context, int index) {
                  final ingredient = recipe.ingredients[index];
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('• ${ingredient.toString()}', style: pw.TextStyle(font: ttf)),
                        if (ingredient.notes.isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 16, top: 2),
                            child: pw.Text(ingredient.notes, style: pw.TextStyle(font: italicTtf, color: PdfColors.grey600)),
                          ),
                      ]
                    )
                  );
                },
              ),
              pw.Divider(height: 32),
              pw.Text('Instructions', style: pw.TextStyle(font: boldTtf, fontSize: 18)),
              pw.SizedBox(height: 8),
              pw.ListView.builder(
                itemCount: recipe.instructions.length,
                itemBuilder: (pw.Context context, int index) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(width: 24, child: pw.Text('${index + 1}.', style: pw.TextStyle(font: ttf))),
                        pw.Expanded(child: pw.Text(recipe.instructions[index], style: pw.TextStyle(font: ttf))),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(recipe.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (recipe.sourceUrl.isNotEmpty)
              InkWell(
                onTap: _launchSourceUrl,
                child: Text('Source: ${recipe.sourceUrl}', style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis),
              ),
            const SizedBox(height: 8),
            if (recipe.description.isNotEmpty) Text(recipe.description, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[700])),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16.0, runSpacing: 8.0,
              children: [
                if(recipe.prepTime.isNotEmpty) InfoChip(icon: Icons.timer_outlined, label: "Prep: ${recipe.prepTime}"),
                if(recipe.cookTime.isNotEmpty) InfoChip(icon: Icons.whatshot_outlined, label: "Cook: ${recipe.cookTime}"),
                if(recipe.totalTime.isNotEmpty) InfoChip(icon: Icons.access_time, label: "Total: ${recipe.totalTime}"),
                if(recipe.servings.isNotEmpty) InfoChip(icon: Icons.people_outline, label: "Serves: ${recipe.servings}"),
              ],
            ),
            const Divider(height: 32.0),
            Text("Ingredients", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (var ingredient in recipe.ingredients) 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("• ${ingredient.toString()}", style: Theme.of(context).textTheme.bodyLarge),
                    if (ingredient.notes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 2),
                        child: Text(ingredient.notes, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[600])),
                      )
                  ],
                ),
              ),
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
                  title: Text(recipe.instructions[index], style: Theme.of(context).textTheme.bodyLarge),
                );
              },
            ),
            const Divider(height: 32.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (recipe.id == null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save_alt_outlined),
                    label: const Text('Save'),
                    onPressed: () async {
                      // Capture the context-dependent object and other data before the async gap.
                      final messenger = ScaffoldMessenger.of(context);
                      final recipeTitle = recipe.title;

                      await DatabaseHelper.instance.insert(recipe);

                      messenger.showSnackBar(SnackBar(content: Text('"$recipeTitle" saved!')));
                    },
                  ),
                if (recipe.id != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeEditScreen(recipe: recipe)));
                    },
                  ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                  onPressed: () async {
                    final pdfData = await _generatePdf(PdfPageFormat.letter, recipe);
                    await Printing.sharePdf(bytes: pdfData, filename: '${recipe.title}.pdf');
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print'),
                  onPressed: () async {
                    final pdfData = await _generatePdf(PdfPageFormat.letter, recipe);
                    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfData);
                  },
                ),
                // New Delete Button
                if (recipe.id != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                    onPressed: () async {
                      // Capture context-dependent objects and other data before the async gap.
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      final recipeTitle = recipe.title;

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext dialogContext) => AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: Text('Are you sure you want to delete "${recipe.title}"?'),
                          actions: <Widget>[
                            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await DatabaseHelper.instance.delete(recipe.id!);
                        messenger.showSnackBar(SnackBar(content: Text('"$recipeTitle" deleted')));
                        navigator.pop(); // Go back to the library screen
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}