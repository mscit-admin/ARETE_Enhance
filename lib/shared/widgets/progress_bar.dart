import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// A thin rounded progress bar with a lime gradient fill.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({super.key, required this.value, this.height = 7});

  /// 0.0 – 1.0
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(height: height, color: p.line),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              height: height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accentPressed, AppColors.accent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
