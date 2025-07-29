// lib/widgets/dashboard_card.dart

import 'package:flutter/material.dart';

/// A reusable card widget for the main dashboard screen.
class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 40.0, color: Theme.of(context).primaryColor),
              const SizedBox(height: 16.0),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4.0),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}