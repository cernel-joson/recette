import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/core/presentation/controllers/job_controller.dart';

/// An icon for the AppBar that provides a visual indication of background
/// job activity and serves as a button to open the Jobs Tray screen.
class JobsTrayIcon extends StatelessWidget {
  /// A callback function that is executed when the icon is tapped.
  final VoidCallback onTap;

  const JobsTrayIcon({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Listen to the JobController to know if there are active jobs.
    final hasActiveJobs =
        context.select((JobController controller) => controller.hasActiveJobs);

    return IconButton(
      onPressed: onTap,
      icon: hasActiveJobs
          // If jobs are active, show a spinning progress indicator.
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                // color: Colors.white,
              ),
            )
          // Otherwise, show a standard history icon.
          : const Icon(Icons.history),
    );
  }
}