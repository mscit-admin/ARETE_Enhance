import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

/// A selectable option row used throughout the assessment. Shows a radio (single
/// select) or check (multi select) affordance on the right.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.subtitle,
    this.multi = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? leading;
  final String? subtitle;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected ? p.emberSoft : p.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: selected ? AppColors.ember : p.line,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  Text(leading!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: context.textStyles.titleMedium?.copyWith(
                            color: selected ? AppColors.ember : p.text,
                          )),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: context.textStyles.bodySmall
                                ?.copyWith(color: p.muted)),
                    ],
                  ),
                ),
                _indicator(p),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _indicator(AppPalette p) {
    if (multi) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: selected ? AppColors.ember : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: selected ? AppColors.ember : p.line, width: 2),
        ),
        child: selected
            ? const Icon(Icons.check, size: 15, color: Colors.white)
            : null,
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: selected ? AppColors.ember : p.line, width: 2),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                    color: AppColors.ember, shape: BoxShape.circle),
              ),
            )
          : null,
    );
  }
}
