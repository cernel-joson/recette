import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/recipe_model.dart';

/// A helper class to handle the generation, printing, and sharing of recipe PDFs.
class PdfGenerator {
  /// Generates a PDF for the given recipe and opens the native print dialog.
  static Future<void> generateAndPrintRecipe(Recipe recipe) async {
    final pdf = await _generatePdf(recipe);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf);
  }

  /// Generates a PDF for the given recipe and opens the native share dialog.
  static Future<void> generateAndShareRecipe(Recipe recipe) async {
    final pdf = await _generatePdf(recipe);
    await Printing.sharePdf(bytes: pdf, filename: '${recipe.title}.pdf');
  }

  /// The core private function that creates the PDF document in memory.
  static Future<Uint8List> _generatePdf(Recipe recipe) async {
    final pdf = pw.Document();

    // Load the custom font that supports a wide range of characters.
    // This is crucial for fixing issues with special characters like '•' or '—'.
    final fontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.MultiPage(
        // Use the loaded font as the default theme for the document.
        theme: pw.ThemeData.withFont(base: ttf),
        pageFormat: PdfPageFormat.letter,
        build: (pw.Context context) {
          return [
            // --- Header ---
            pw.Header(
              level: 0,
              child: pw.Text(recipe.title,
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),

            // --- Description ---
            if (recipe.description.isNotEmpty)
              pw.Paragraph(
                  text: recipe.description,
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            pw.SizedBox(height: 10),

            // --- Time and Servings Info ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (recipe.prepTime.isNotEmpty) pw.Text("Prep: ${recipe.prepTime}"),
                if (recipe.cookTime.isNotEmpty) pw.Text("Cook: ${recipe.cookTime}"),
                if (recipe.totalTime.isNotEmpty) pw.Text("Total: ${recipe.totalTime}"),
                if (recipe.servings.isNotEmpty) pw.Text("Serves: ${recipe.servings}"),
              ]
            ),
            pw.Divider(height: 20),

            // --- Ingredients ---
            pw.Header(level: 1, text: 'Ingredients'),
            // CORRECTED: Iterate through ingredients and create a pw.Bullet for each one.
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: recipe.ingredients
                  .map((ingredient) => pw.Bullet(text: ingredient.toString()))
                  .toList(),
            ),
            pw.SizedBox(height: 20),

            // --- Instructions ---
            pw.Header(level: 1, text: 'Instructions'),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: List.generate(recipe.instructions.length, (index) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 20,
                        child: pw.Text('${index + 1}.'),
                      ),
                      pw.Expanded(
                        child: pw.Text(recipe.instructions[index]),
                      ),
                    ],
                  ),
                );
              }),
            ),
            pw.SizedBox(height: 20),

            // --- Source URL ---
            if (recipe.sourceUrl.isNotEmpty && recipe.sourceUrl.startsWith('http'))
              pw.UrlLink(
                destination: recipe.sourceUrl,
                child: pw.Text('Source: ${recipe.sourceUrl}', style: const pw.TextStyle(color: PdfColors.blue))
              )
          ];
        },
      ),
    );

    // Save the PDF to a Uint8List object and return it.
    return pdf.save();
  }
}