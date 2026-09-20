import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/nutrition.dart';
import '../../data/models/trainer_plan.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/gradient_avatar.dart';
import '../../shared/widgets/pill.dart';
import '../../state/connect_controller.dart';
import '../../state/meal_plans_controller.dart';
import '../../state/plans_controller.dart';
import 'create_plan_screen.dart';
import 'meal_plans_screen.dart';
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
      context.read<MealPlansController>().load();
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
    // Optionally also assign a meal plan to the same member (cross-link).
    String? mealPlanId;
    final mealPlans = context.read<MealPlansController>().plans;
    if (mealPlans.isNotEmpty) {
      mealPlanId = await showModalBottomSheet<String?>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => _MealLinkSheet(mealPlans: mealPlans),
      );
      if (!mounted) return;
    }
    final err = await context
        .read<PlansController>()
        .assign(plan.id, memberId, mealPlanId: mealPlanId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? l.plansAssignedOk)),
    );
  }

  Future<void> _edit(TrainerPlan plan) async {
    // Load the full plan (with exercises) before opening the editor.
    final full = await context.read<PlansController>().fetchDetail(plan.id);
    if (!mounted || full == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreatePlanScreen(existing: full)),
    );
  }

  Future<void> _delete(TrainerPlan plan) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.plansDeletePlan),
        content: Text(l.plansDeleteConfirm(plan.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.actionCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.plansDeletePlan),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final err = await context.read<PlansController>().deletePlan(plan.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? l.plansDeleted)),
    );
  }

  Future<void> _manageAssignees(TrainerPlan plan) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _AssigneesSheet(plan: plan),
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
            tooltip: l.mealPlansTitle,
            icon: const Icon(Icons.restaurant_menu),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MealPlansScreen()),
            ),
          ),
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
                          onEdit: () => _edit(plan),
                          onDelete: () => _delete(plan),
                          onManageAssignees: () => _manageAssignees(plan),
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
  const _PlanCard({
    required this.plan,
    required this.onTap,
    required this.onAssign,
    required this.onEdit,
    required this.onDelete,
    required this.onManageAssignees,
  });
  final TrainerPlan plan;
  final VoidCallback onTap;
  final VoidCallback onAssign;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageAssignees;

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
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: p.muted),
                onSelected: (v) {
                  switch (v) {
                    case 'edit':
                      onEdit();
                    case 'assignees':
                      onManageAssignees();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      const Icon(Icons.edit_outlined, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l.plansEditPlan),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'assignees',
                    child: Row(children: [
                      const Icon(Icons.group_outlined, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l.plansManageAssignees),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete_outline,
                          size: 18, color: AppColors.danger),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l.plansDeletePlan,
                          style: const TextStyle(color: AppColors.danger)),
                    ]),
                  ),
                ],
              ),
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
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.limeTintBorder),
                backgroundColor: AppColors.limeTintBg,
              ),
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

/// Lists the members a plan is assigned to and lets the trainer unassign any.
class _AssigneesSheet extends StatefulWidget {
  const _AssigneesSheet({required this.plan});
  final TrainerPlan plan;

  @override
  State<_AssigneesSheet> createState() => _AssigneesSheetState();
}

class _AssigneesSheetState extends State<_AssigneesSheet> {
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows =
        await context.read<PlansController>().assignees(widget.plan.id);
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _unassign(Map<String, dynamic> m) async {
    final l = AppLocalizations.of(context);
    final err = await context
        .read<PlansController>()
        .unassign(widget.plan.id, m['id'] as String);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? l.plansUnassigned)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.plansAssignees, style: context.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _rows.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg),
                          child: Text(l.plansNoAssignees,
                              style: context.textStyles.bodyMedium
                                  ?.copyWith(color: p.muted)),
                        )
                      : ListView(
                          shrinkWrap: true,
                          children: [
                            for (final m in _rows)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: GradientAvatar(
                                    initials: initialsFrom(
                                        (m['fullName'] as String?) ?? 'Client'),
                                    size: 40),
                                title: Text(
                                    (m['fullName'] as String?) ?? 'Client'),
                                trailing: TextButton.icon(
                                  style: TextButton.styleFrom(
                                      foregroundColor: AppColors.danger),
                                  onPressed: () => _unassign(m),
                                  icon: const Icon(Icons.person_remove_alt_1,
                                      size: 18),
                                  label: Text(l.plansUnassign),
                                ),
                              ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Optional picker shown after assigning a workout plan: choose a meal plan to
/// also assign to the same member, or skip.
class _MealLinkSheet extends StatelessWidget {
  const _MealLinkSheet({required this.mealPlans});
  final List<MealPlan> mealPlans;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.mealLinkTitle, style: context.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(l.mealLinkSubtitle,
                style: context.textStyles.bodySmall?.copyWith(color: p.muted)),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final mp in mealPlans)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.restaurant_menu,
                          color: AppColors.accent),
                      title: Text(mp.title),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).pop(mp.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text(l.mealLinkSkip),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
