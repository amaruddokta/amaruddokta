// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';

/// A reusable bottom navigation icon with label.
class BottomIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const BottomIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: color),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
