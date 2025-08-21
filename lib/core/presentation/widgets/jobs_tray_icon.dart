import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/core/jobs/presentation/controllers/job_controller.dart';
// --- ADD THIS IMPORT ---
import 'package:recette/core/presentation/screens/jobs_tray_screen.dart';

class JobsTrayIcon extends StatefulWidget {
  const JobsTrayIcon({super.key});

  @override
  State<JobsTrayIcon> createState() => _JobsTrayIconState();
}

class _JobsTrayIconState extends State<JobsTrayIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JobController>(
      builder: (context, controller, child) {
        // Start or stop the animation based on the controller's state.
        if (controller.hasActiveJobs) {
          _animationController.repeat();
        } else {
          _animationController.stop();
        }

        return IconButton(
          icon: controller.hasActiveJobs
              ? RotationTransition(
                  turns: _animationController,
                  child: const Icon(Icons.sync),
                )
              : const Icon(Icons.history),
          tooltip: 'Job History',
          onPressed: () {
            // --- THIS IS THE FIX ---
            // Navigate to the new JobsTrayScreen.
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JobsTrayScreen()),
            );
          },
        );
      },
    );
  }
}