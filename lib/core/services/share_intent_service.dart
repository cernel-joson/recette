import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:recette/features/recipes/recipes.dart';
import 'package:provider/provider.dart';

/// A service to handle intents from the OS "Share" menu.
class ShareIntentService {
  ShareIntentService._();
  static final instance = ShareIntentService._();

  StreamSubscription? _intentSub;
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Initializes the listeners for sharing intents.
  /// This should be called once from a top-level widget like MainScreen.
  void init(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;

    // Listen to media sharing coming from outside the app while it is launched.
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      if (value.isNotEmpty) _handleSharedIntent(value.first);
    }, onError: (err) {
      debugPrint("getMediaStream error: $err");
    });

    // Get the media sharing coming from outside the app while the app is closed.
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty) _handleSharedIntent(value.first);
    });
  }

  /// Handles a single shared file by creating a background job.
  void _handleSharedIntent(SharedMediaFile file) {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      debugPrint("ShareIntentService: Navigator context is null, cannot handle share.");
      return;
    }
    
    final importService = Provider.of<RecipeImportService>(context, listen: false);
    
    // Show a confirmation snackbar immediately to inform the user.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shared content received! Parsing in the background...'),
        backgroundColor: Colors.blue,
      ),
    );

    // Use the import service to submit the job asynchronously
    try {
      if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
        importService.importFromUrl(file.path);
      } else if (file.type == SharedMediaType.image) {
        importService.importFromImage(file.path);
      } else {
        // Ignore unsupported share types.
        debugPrint("Received unsupported share type: ${file.type}");
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing share: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  /// Disposes the stream subscription to prevent memory leaks.
  void dispose() {
    _intentSub?.cancel();
  }
}