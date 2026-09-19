import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/gradient_avatar.dart';
import '../../state/meal_plan_builder_controller.dart';
import 'meal_plan_builder_screen.dart';

/// Trainer-side management of assigned meal plans: lists the members who have a
/// plan, and lets the coach edit or remove each — mirroring the workout Plans
/// tab. A new plan is authored in the meal-plan builder.
class MealPlansScreen extends StatefulWidget {
  const MealPlansScreen({super.key});

  @override
  State<MealPlansScreen> createState() => _MealPlansScreenState();
}

class _MealPlansScreenState extends State<MealPlansScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final rows =
        await context.read<MealPlanBuilderController>().assignedMembers();
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _openBuilder({String? memberId, String? name}) async {
    // Start from a clean builder so "new" shows the client picker and "edit"
    // deep-links into the chosen member.
    context.read<MealPlanBuilderController>().clear();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MealPlanBuilderScreen(
          preselectMemberId: memberId,
          preselectMemberName: name,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _loading = true);
    await _load();
  }

  Future<void> _remove(Map<String, dynamic> m) async {
    final l = AppLocalizations.of(context);
    final name = (m['memberName'] as String?)?.trim();
    final displayName = (name == null || name.isEmpty) ? 'this member' : name;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.mealPlanRemove),
        content: Text(l.mealPlanRemoveConfirm(displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.actionCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.mealPlanRemove),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context
        .read<MealPlanBuilderController>()
        .unassign(m['memberId'] as String);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.mealPlanRemoved)));
    setState(() => _loading = true);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.mealPlansTitle),
        actions: [
          IconButton(
            tooltip: l.plansNewPlan,
            icon: const Icon(Icons.add),
            onPressed: () => _openBuilder(),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _rows.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restaurant_menu_outlined,
                              size: 40, color: p.muted),
                          const SizedBox(height: AppSpacing.md),
                          Text(l.mealPlansEmpty,
                              textAlign: TextAlign.center,
                              style: context.textStyles.bodyMedium
                                  ?.copyWith(color: p.muted)),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                        AppSpacing.lg, AppSpacing.screen, 96),
                    children: [
                      for (final m in _rows) ...[
                        _MealPlanRow(
                          row: m,
                          onEdit: () => _openBuilder(
                            memberId: m['memberId'] as String,
                            name: m['memberName'] as String?,
                          ),
                          onRemove: () => _remove(m),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _MealPlanRow extends StatelessWidget {
  const _MealPlanRow(
      {required this.row, required this.onEdit, required this.onRemove});
  final Map<String, dynamic> row;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final name = (row['memberName'] as String?)?.trim();
    final displayName = (name == null || name.isEmpty) ? 'Client' : name;
    final title = (row['title'] as String?) ?? '';
    return AppCard(
      onTap: onEdit,
      child: Row(
        children: [
          GradientAvatar(initials: initialsFrom(displayName), size: 42),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: context.textStyles.titleMedium),
                if (title.isNotEmpty)
                  Text(title,
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: p.muted)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: p.muted),
            onSelected: (v) {
              switch (v) {
                case 'edit':
                  onEdit();
                case 'remove':
                  onRemove();
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
                value: 'remove',
                child: Row(children: [
                  const Icon(Icons.delete_outline,
                      size: 18, color: AppColors.danger),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l.mealPlanRemove,
                      style: const TextStyle(color: AppColors.danger)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
