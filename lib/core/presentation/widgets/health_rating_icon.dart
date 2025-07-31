import 'package:flutter/material.dart';

class HealthRatingIcon extends StatelessWidget {
  final String? healthRating;
  const HealthRatingIcon({super.key, this.healthRating});

  @override
  Widget build(BuildContext context) {
    switch (healthRating) {
      case 'GREEN':
        return const Text('🟢', style: TextStyle(fontSize: 20));
      case 'YELLOW':
        return const Text('🟡', style: TextStyle(fontSize: 20));
      case 'RED':
        return const Text('🔴', style: TextStyle(fontSize: 20));
      default:
        // A neutral icon for "UNRATED" or null
        return const Icon(Icons.circle_outlined, color: Colors.grey);
    }
  }
}