import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/progress.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pill.dart';
import '../../shared/widgets/section_label.dart';
import '../../shared/widgets/stat_tile.dart';
import '../../state/profile_controller.dart' show LoadStatus;
import '../../state/progress_controller.dart';
import 'widgets/volume_bar_chart.dart';
import 'widgets/weight_line_chart.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = context.read<ProgressController>();
      if (c.status == LoadStatus.idle) c.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProgressController>();
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navProgress),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: SizedBox.shrink(),
        ),
      ),
      body: SafeArea(
        child: switch (controller.status) {
          LoadStatus.idle || LoadStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          LoadStatus.error =>
            Center(child: Text(l.progressCouldNotLoad)),
          LoadStatus.ready => _Dashboard(data: controller.data!),
        },
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.data});

  final ProgressData data;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final change = data.weightChange;
    final down = change <= 0;
    final l = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.md, AppSpacing.screen, AppSpacing.xxxl),
      children: [
        Text(l.progressLast12Weeks,
            style: context.textStyles.bodySmall?.copyWith(color: p.muted)),
        const SizedBox(height: AppSpacing.md),

        // ---- Weight trend ----
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(data.currentWeight.toStringAsFixed(1),
                          style: context.textStyles.displaySmall),
                      const SizedBox(width: 4),
                      Text('kg',
                          style: context.textStyles.bodySmall
                              ?.copyWith(color: p.muted)),
                    ],
                  ),
                  Pill(
                    '${down ? '' : '+'}${change.toStringAsFixed(1)} kg',
                    tone: down ? PillTone.teal : PillTone.ember,
                    icon: down ? Icons.arrow_downward : Icons.arrow_upward,
                  ),
                ],
              ),
              Text(l.progressBodyWeight,
                  style:
                      context.textStyles.bodySmall?.copyWith(color: p.muted)),
              const SizedBox(height: AppSpacing.md),
              WeightLineChart(
                values: [for (final w in data.weight) w.kg],
                color: AppColors.ember,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ---- Quick stats ----
        Row(
          children: [
            Expanded(
                child: _MiniStat(
                    value: '${data.totalWorkouts}',
                    label: l.progressWorkouts,
                    color: p.text)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: _MiniStat(
                    value: '${data.totalPRs}',
                    label: l.progressPrsSet,
                    color: AppColors.teal)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: _MiniStat(
                    value: '${data.streakDays}',
                    label: l.progressDayStreak,
                    color: AppColors.ember)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // ---- Weekly volume ----
        SectionLabel(l.progressWeeklyVolume),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(data.thisWeekVolume / 1000).toStringAsFixed(1)}k kg',
                      style: context.textStyles.titleLarge),
                  Text(l.progressThisWeek,
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: p.muted)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              VolumeBarChart(
                values: [for (final v in data.volume) v.volumeKg],
                color: AppColors.teal,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ---- Personal records ----
        SectionLabel(l.progressPersonalRecords),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          child: Column(
            children: [
              for (final r in data.records) _RecordRow(record: r),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ---- Measurements ----
        SectionLabel(l.progressMeasurements),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 2.4,
          children: [
            for (final m in data.measurements) _MeasurementCard(measurement: m),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // ---- Progress photos ----
        SectionLabel(l.progressPhotos),
        const SizedBox(height: AppSpacing.sm),
        _PhotoStrip(count: data.photoCount),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: StatTile(value: value, label: label, valueColor: color),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record});
  final PersonalRecord record;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: AppColors.gold, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.exercise, style: context.textStyles.titleMedium),
                Text(DateFormat('MMM d, yyyy').format(record.achievedOn),
                    style: context.textStyles.bodySmall
                        ?.copyWith(color: p.muted)),
              ],
            ),
          ),
          Text(
            '${record.weightKg.toStringAsFixed(record.weightKg % 1 == 0 ? 0 : 1)}kg × ${record.reps}',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: p.text,
                fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard({required this.measurement});
  final Measurement measurement;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final m = measurement;
    final color = m.unchanged
        ? p.muted
        : (m.improved ? AppColors.teal : AppColors.ember);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(m.label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: p.muted)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${m.value.toStringAsFixed(m.value % 1 == 0 ? 0 : 1)}',
                  style: context.textStyles.titleLarge),
              const SizedBox(width: 2),
              Text(m.unit,
                  style: context.textStyles.bodySmall
                      ?.copyWith(color: p.muted)),
              const Spacer(),
              Text(
                '${m.delta > 0 ? '+' : ''}${m.delta.toStringAsFixed(m.delta % 1 == 0 ? 0 : 1)}',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: 108,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add-photo tile.
          _tile(
            context,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined, color: p.muted),
                const SizedBox(height: 4),
                Text(l.progressAdd,
                    style: context.textStyles.bodySmall
                        ?.copyWith(color: p.muted)),
              ],
            ),
            dashed: true,
          ),
          for (var i = 0; i < count; i++)
            _tile(
              context,
              child: Center(
                child: Icon(Icons.image_outlined,
                    color: p.muted.withValues(alpha: 0.6), size: 30),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context,
      {required Widget child, bool dashed = false}) {
    final p = context.palette;
    return Container(
      width: 84,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: dashed ? p.muted.withValues(alpha: 0.5) : p.line),
      ),
      child: child,
    );
  }
}
