import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/member.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/stat_tile.dart';

/// The four-up body-metrics strip: weight / BMI / body-fat / weeks as member.
class ProfileMetricsCard extends StatelessWidget {
  const ProfileMetricsCard({super.key, required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final weeks = DateTime.now()
            .difference(member.membership.joinedOn)
            .inDays ~/
        7;

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          StatTile(
            value: member.displayWeight.toStringAsFixed(1),
            unit: member.units.weightUnit,
            label: 'Weight',
          ),
          StatTile(
            value: member.metrics.bmi.toStringAsFixed(1),
            label: 'BMI',
          ),
          StatTile(
            value: member.metrics.bodyFatPercent == null
                ? '—'
                : '${member.metrics.bodyFatPercent!.toStringAsFixed(0)}%',
            label: 'Body Fat',
          ),
          StatTile(
            value: '$weeks',
            label: 'Weeks',
          ),
        ],
      ),
    );
  }
}
