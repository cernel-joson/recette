import 'package:flutter/material.dart';

/// A small, reusable widget to display a piece of information with an icon.
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const InfoChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 4),
        // By wrapping the Text in Flexible, we allow it to wrap to a new
        // line if the text is too long to fit, preventing an overflow error.
        Flexible(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}