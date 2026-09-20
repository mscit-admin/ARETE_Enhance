import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/nutrition.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/gradient_avatar.dart';
import '../../shared/widgets/pill.dart';
import '../../state/connect_controller.dart';
import '../../state/meal_plans_controller.dart';
import '../../state/plans_controller.dart';
import 'meal_plan_builder_screen.dart';

/// Trainer-side Meal Plans: author named meal-plan templates and assign them to
/// clients — mirroring the workout Plans tab. Assigning can optionally also
/// assign a workout plan to the same members (cross-link).
class MealPlansScreen extends StatefulWidget {
  const MealPlansScreen({super.key});

  @override
  State<MealPlansScreen> createState() => _MealPlansScreenState();
}

class _MealPlansScreenState extends State<MealPlansScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealPlansController>().load();
      context.read<ConnectController>().loadClients();
      context.read<PlansController>().load();
    });
  }

  Future<void> _new() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MealPlanBuilderScreen()),
    );
    if (mounted) context.read<MealPlansController>().load();
  }

  Future<void> _edit(MealPlan plan) async {
    final full = await context.read<MealPlansController>().fetchDetail(plan.id);
    if (!mounted || full == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MealPlanBuilderScreen(existing: full)),
    );
    if (mounted) context.read<MealPlansController>().load();
  }

  Future<void> _delete(MealPlan plan) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.plansDeletePlan),
        content: Text(l.plansDeleteConfirm(plan.title)),
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
    if (ok != true || !mounted) return;
    final err = await context.read<MealPlansController>().deletePlan(plan.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(err ?? l.plansDeleted)));
  }

  Future<void> _assign(MealPlan plan) async {
    final l = AppLocalizations.of(context);
    final clients = context.read<ConnectController>().clients;
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.plansNoClients)));
      return;
    }
    final workoutPlans = context.read<PlansController>().plans;
    final result = await showModalBottomSheet<_AssignResult>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _AssignSheet(clients: clients, workoutPlans: workoutPlans),
    );
    if (result == null || result.memberIds.isEmpty || !mounted) return;
    final err = await context.read<MealPlansController>().assign(
          plan.id,
          result.memberIds,
          workoutPlanId: result.workoutPlanId,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? l.plansAssignedOk)),
    );
  }

  Future<void> _manageAssignees(MealPlan plan) async {
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
    final controller = context.watch<MealPlansController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.mealPlansTitle),
        actions: [
          IconButton(
            tooltip: l.plansNewPlan,
            icon: const Icon(Icons.add),
            onPressed: _new,
          ),
        ],
      ),
      body: SafeArea(
        child: controller.loading && controller.plans.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : controller.plans.isEmpty
                ? _Empty(l: l)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, 96),
                    children: [
                      for (final plan in controller.plans) ...[
                        _PlanCard(
                          plan: plan,
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
            Icon(Icons.restaurant_menu_outlined, size: 40, color: p.muted),
            const SizedBox(height: AppSpacing.md),
            Text(l.mealPlansEmpty,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyMedium?.copyWith(color: p.muted)),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onAssign,
    required this.onEdit,
    required this.onDelete,
    required this.onManageAssignees,
  });
  final MealPlan plan;
  final VoidCallback onAssign;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageAssignees;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return AppCard(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(plan.title, style: context.textStyles.titleMedium),
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
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(plan.description,
                style: context.textStyles.bodySmall?.copyWith(color: p.muted)),
          ],
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

class _AssignResult {
  const _AssignResult(this.memberIds, this.workoutPlanId);
  final List<String> memberIds;
  final String? workoutPlanId;
}

/// Multi-select members to assign the meal plan to, plus an optional workout
/// plan to assign to the same members (cross-link).
class _AssignSheet extends StatefulWidget {
  const _AssignSheet({required this.clients, required this.workoutPlans});
  final List<Map<String, dynamic>> clients;
  final List<dynamic> workoutPlans; // TrainerPlan list

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  final Set<String> _selected = {};
  String? _workoutPlanId;

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
            Text(l.mealAssignTitle, style: context.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(l.mealAssignSelectMembers,
                style: context.textStyles.bodySmall?.copyWith(color: p.muted)),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final c in widget.clients)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _selected.contains(c['id'] as String),
                      onChanged: (v) => setState(() {
                        final id = c['id'] as String;
                        if (v == true) {
                          _selected.add(id);
                        } else {
                          _selected.remove(id);
                        }
                      }),
                      secondary: GradientAvatar(
                          initials: initialsFrom(
                              (c['full_name'] as String?) ?? 'Client'),
                          size: 36),
                      title: Text((c['full_name'] as String?) ?? 'Client'),
                    ),
                ],
              ),
            ),
            if (widget.workoutPlans.isNotEmpty) ...[
              const Divider(),
              Text(l.mealAssignAlsoWorkout,
                  style: context.textStyles.bodySmall?.copyWith(color: p.muted)),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String?>(
                value: _workoutPlanId,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l.mealAssignNone),
                  ),
                  for (final wp in widget.workoutPlans)
                    DropdownMenuItem<String?>(
                      value: (wp as dynamic).id as String,
                      child: Text((wp as dynamic).name as String),
                    ),
                ],
                onChanged: (v) => setState(() => _workoutPlanId = v),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(
                          _AssignResult(_selected.toList(), _workoutPlanId),
                        ),
                icon: const Icon(Icons.check, size: 18),
                label: Text(l.plansAssign),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssigneesSheet extends StatefulWidget {
  const _AssigneesSheet({required this.plan});
  final MealPlan plan;

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
        await context.read<MealPlansController>().assignees(widget.plan.id);
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _unassign(Map<String, dynamic> m) async {
    final l = AppLocalizations.of(context);
    final err = await context
        .read<MealPlansController>()
        .unassign(widget.plan.id, m['id'] as String);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(err ?? l.plansUnassigned)));
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
                          padding:
                              const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
