import 'package:flutter/material.dart';
import 'package:recette/core/services/export_service.dart';
import 'package:recette/core/services/import_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ExportService _exportService = ExportService();
  final ImportService _importService = ImportService(); // 2. ADD IMPORT SERVICE
  bool _isBusy = false; // Combined loading state for both import and export

  // --- NEW: Shows a bottom sheet with export options ---
  Future<void> _showExportOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.save_alt_outlined),
              title: const Text('Save to Device...'),
              subtitle: const Text('Opens a dialog to save the backup file.'),
              onTap: () {
                Navigator.of(context).pop();
                _exportData(useSaveAs: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              subtitle: const Text('Opens the share dialog to send the file.'),
              onTap: () {
                Navigator.of(context).pop();
                _exportData(useSaveAs: false);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportData({required bool useSaveAs}) async {
    setState(() {
      _isBusy = true;
    });

    try {
      if (useSaveAs) {
        final resultPath = await _exportService.exportDataAndSaveAs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export finished: $resultPath'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _exportService.exportDataAndShare();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  // --- NEW: Method to handle the import process ---
  Future<void> _importData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Overwrite All Data?'),
        content: const Text(
            'Importing a backup file will permanently delete all of your current recipes, inventory, and plans. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import & Overwrite'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isBusy = true;
    });

    try {
      await _importService.pickAndImportData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import complete! Restart the app to see changes.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text('Export All Data'),
            subtitle: const Text('Save a backup of your data to a file.'),
            onTap: _isBusy ? null : _showExportOptions,
            trailing: _isBusy
                ? const CircularProgressIndicator()
                : const Icon(Icons.chevron_right),
          ),
          const Divider(),
          ListTile( // 3. ADD IMPORT BUTTON
            leading: const Icon(Icons.download_for_offline_outlined),
            title: const Text('Import from Backup'),
            subtitle: const Text('Restore your data from a backup file.'),
            onTap: _isBusy ? null : _importData,
            trailing: _isBusy
                ? const CircularProgressIndicator()
                : const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}