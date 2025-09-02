// lib/core/presentation/screens/about_screen.dart

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:recette/core/data/services/developer_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '...';
  int _tapCount = 0;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = 'Version ${packageInfo.version} (${packageInfo.buildNumber})';
      });
    }
  }

  void _handleTap() {
    // Hide any previous snackbar before showing a new one.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    setState(() {
      _tapCount++;
    });

    final devService = Provider.of<DeveloperService>(context, listen: false);

    if (devService.isDeveloperMode) {
      // If it's already on, do nothing.
      setState(() => _tapCount = 0);
      return;
    }

    if (_tapCount >= 7) {
      devService.enableDeveloperMode();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Developer Mode Enabled!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _tapCount = 0);
    } else if (_tapCount >= 3) {
      // --- THIS IS THE FIX ---
      // Show feedback after the 3rd tap.
      final remainingTaps = 7 - _tapCount;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are now $remainingTaps steps away from being a developer.'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Recette'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FlutterLogo(size: 80),
            const SizedBox(height: 24),
            Text(
              'Recette',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _handleTap,
              child: Text(
                _version,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}