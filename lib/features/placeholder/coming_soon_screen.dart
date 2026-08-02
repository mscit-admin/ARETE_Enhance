import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/pill.dart';

/// Placeholder for modules not yet built in this slice. Communicates exactly
/// which Phase 1 module lands here so the roadmap stays visible in the app.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.moduleName,
    required this.description,
    required this.icon,
  });

  final String title;
  final String moduleName;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: p.emberSoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Icon(icon, size: 40, color: AppColors.accent),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Pill('Phase 1 · Coming next', tone: PillTone.ember),
              const SizedBox(height: AppSpacing.md),
              Text(
                moduleName,
                style: context.textStyles.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                style: context.textStyles.bodyMedium?.copyWith(color: p.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
