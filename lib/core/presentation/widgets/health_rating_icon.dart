import 'package:flutter/material.dart';

class HealthRatingIcon extends StatelessWidget {
  final String? healthRating;
  const HealthRatingIcon({super.key, this.healthRating});

  @override
  Widget build(BuildContext context) {
    switch (healthRating) {
      // New Cases
      case 'SAFE':
      // Legacy Case
      case 'GREEN':
        return const Text('✅', style: TextStyle(fontSize: 20));

      // New Cases
      case 'CAUTION':
      // Legacy Case
      case 'YELLOW':
        return const Text('⚠️', style: TextStyle(fontSize: 20));
      
      // New Cases
      case 'AVOID':
      // Legacy Case
      case 'RED':
        return const Text('❌', style: TextStyle(fontSize: 20));
      default:
        // A neutral icon for "UNRATED" or null
        return const Icon(Icons.circle_outlined, color: Colors.grey);
    }
  }
}