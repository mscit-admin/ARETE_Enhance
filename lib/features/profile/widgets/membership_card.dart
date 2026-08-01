import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/enums.dart';
import '../../../core/l10n/enum_labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/member.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/pill.dart';

/// The dark "membership" hero card: tier, status and renewal date.
class MembershipCard extends StatelessWidget {
  const MembershipCard({super.key, required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final m = member.membership;
    final df = DateFormat('MMM d, yyyy');
    final statusTone = switch (m.status) {
      MembershipStatus.active => PillTone.teal,
      MembershipStatus.frozen => PillTone.gold,
      MembershipStatus.expired => PillTone.ember,
    };
    final l = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.slate, Color(0xFF12161B)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.membershipTitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              Pill(m.status.localized(l), tone: statusTone),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                m.tier.localized(l),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.workspace_premium,
                  color: AppColors.gold, size: 22),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _meta(l.membershipSince, df.format(m.joinedOn)),
              const SizedBox(width: AppSpacing.xl),
              _meta(l.membershipRenews, df.format(m.renewsOn)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
