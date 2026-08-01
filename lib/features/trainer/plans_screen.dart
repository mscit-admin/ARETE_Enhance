import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/trainer_plan.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/gradient_avatar.dart';
import '../../shared/widgets/pill.dart';
import '../../state/connect_controller.dart';
import '../../state/plans_controller.dart';
import 'create_plan_screen.dart';
import 'plan_detail_screen.dart';

/// Trainer-side Plans tab: author plans and assign them to clients.
class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlansController>().load();
      context.read<ConnectController>().loadClients();
    });
  }

  Future<void> _openDetail(TrainerPlan summary) async {
    final full =
        await context.read<PlansController>().fetchDetail(summary.id);
    if (!mounted || full == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: full)),
    );
  }

  Future<void> _assign(TrainerPlan plan) async {
    final l = AppLocalizations.of(context);
    final clients = context.read<ConnectController>().clients;
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.plansNoClients)));
      return;
    }
    final memberId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => _AssignSheet(clients: clients),
    );
    if (memberId == null || !mounted) return;
    final err = await context.read<PlansController>().assign(plan.id, memberId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? l.plansAssignedOk)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = context.watch<PlansController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navPlans),
        actions: [
          IconButton(
            tooltip: l.plansNewPlan,
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreatePlanScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: controller.loading && controller.plans.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : controller.plans.isEmpty
                ? _Empty(l: l)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                        AppSpacing.lg, AppSpacing.screen, 96),
                    children: [
                      for (final plan in controller.plans) ...[
                        _PlanCard(
                          plan: plan,
                          onTap: () => _openDetail(plan),
                          onAssign: () => _assign(plan),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 40, color: p.muted),
            const SizedBox(height: AppSpacing.md),
            Text(l.plansEmpty, style: context.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(l.plansEmptyHint,
                textAlign: TextAlign.center,
                style: context.textStyles.bodySmall?.copyWith(color: p.muted)),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard(
      {required this.plan, required this.onTap, required this.onAssign});
  final TrainerPlan plan;
  final VoidCallback onTap;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(plan.name, style: context.textStyles.titleMedium),
              ),
              if ((plan.assignedCount ?? 0) > 0)
                Pill(l.plansAssignedCount(plan.assignedCount!),
                    tone: PillTone.teal),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${l.plansDaysWeeks(plan.daysPerWeek, plan.weeks)} · '
            '${l.plansExercisesCount(plan.exCount)}',
            style: context.textStyles.bodySmall?.copyWith(color: p.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: OutlinedButton.icon(
              onPressed: onAssign,
              icon: const Icon(Icons.person_add_alt, size: 18),
              label: Text(l.plansAssign),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignSheet extends StatelessWidget {
  const _AssignSheet({required this.clients});
  final List<Map<String, dynamic>> clients;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.plansAssignTo, style: context.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            for (final c in clients)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: GradientAvatar(
                    initials:
                        initialsFrom((c['full_name'] as String?) ?? 'Client'),
                    size: 40),
                title: Text((c['full_name'] as String?) ?? 'Client'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pop(c['id'] as String),
              ),
          ],
        ),
      ),
    );
  }
}
