import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/enum_labels.dart';
import '../../core/notifications/reminder_math.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/meal_slot.dart';
import '../../data/models/nutrition.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_label.dart';
import '../../state/coach_nutrition_controller.dart';
import '../alerts/alerts_screen.dart' show formatMinuteOfDay;

/// Coach side: build the meal schedule and water goal for one trainee and send
/// it. The trainee's app applies it to their own schedule, which re-times both
/// their meal and water reminders.
class CoachNutritionPlanScreen extends StatefulWidget {
  const CoachNutritionPlanScreen({
    super.key,
    required this.memberId,
    required this.memberName,
  });

  final String memberId;
  final String memberName;

  @override
  State<CoachNutritionPlanScreen> createState() =>
      _CoachNutritionPlanScreenState();
}

class _CoachNutritionPlanScreenState extends State<CoachNutritionPlanScreen> {
  final _note = TextEditingController();
  List<MealSlot> _slots = [];
  int _waterTarget = NutritionSettings.defaultTargetGlasses;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final c = context.read<CoachNutritionController>();
    await c.load(widget.memberId);
    if (!mounted) return;
    setState(() {
      _slots = c.startingSchedule()..sort(_byTime);
      _waterTarget = c.startingWaterTarget();
      _note.text = c.plan?.note ?? '';
      _ready = true;
    });
  }

  static int _byTime(MealSlot a, MealSlot b) =>
      a.minuteOfDay.compareTo(b.minuteOfDay);

  void _upsert(MealSlot slot) {
    setState(() {
      final i = _slots.indexWhere((s) => s.id == slot.id);
      if (i >= 0) {
        _slots[i] = slot;
      } else {
        _slots.add(slot);
      }
      _slots.sort(_byTime);
    });
  }

  Future<void> _editSlot(MealSlot slot, {bool isNew = false}) async {
    final result = await showModalBottomSheet<MealSlot>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SlotEditor(slot: slot),
    );
    if (result == null) return;
    _upsert(result);
    if (isNew) return;
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final error = await context.read<CoachNutritionController>().send(
          mealSchedule: _slots,
          waterTargetGlasses: _waterTarget,
          note: _note.text.trim(),
        );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? l.coachNutritionSent)),
    );
    if (error == null) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CoachNutritionController>();
    final l = AppLocalizations.of(context);
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: Text(l.coachNutritionTitle(widget.memberName))),
      body: !_ready || c.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                if (c.error != null) ...[
                  AppCard(
                    borderColor: AppColors.danger.withValues(alpha: 0.5),
                    child: Text(c.error!, style: context.textStyles.bodySmall),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (c.plan != null) ...[
                  Text(
                    l.coachNutritionLastSent(_formatDate(c.plan!.createdAt)),
                    style:
                        context.textStyles.bodySmall?.copyWith(color: p.muted),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ---- water goal ----
                SectionLabel(l.nutritionDailyTarget),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.water_drop, color: AppColors.water),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(l.nutritionGlassesCount(_waterTarget),
                            style: context.textStyles.titleMedium),
                      ),
                      IconButton.filledTonal(
                        onPressed: _waterTarget <=
                                NutritionSettings.minTargetGlasses
                            ? null
                            : () => setState(() => _waterTarget--),
                        icon: const Icon(Icons.remove),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filledTonal(
                        onPressed: _waterTarget >=
                                NutritionSettings.maxTargetGlasses
                            ? null
                            : () => setState(() => _waterTarget++),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ---- meals ----
                SectionLabel(l.coachNutritionMeals),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final slot in _slots) ...[
                        ListTile(
                          leading: const Icon(Icons.restaurant_outlined,
                              color: AppColors.gold),
                          title: Text(slot.name.trim().isNotEmpty
                              ? slot.name.trim()
                              : slot.kind.localized(l)),
                          subtitle: Text(
                            slot.note.trim().isEmpty
                                ? formatMinuteOfDay(context, slot.minuteOfDay)
                                : '${formatMinuteOfDay(context, slot.minuteOfDay)} · ${slot.note.trim()}',
                          ),
                          trailing: IconButton(
                            tooltip: l.alertsRemove,
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.danger),
                            onPressed: () => setState(
                                () => _slots.removeWhere((s) => s.id == slot.id)),
                          ),
                          onTap: () => _editSlot(slot),
                        ),
                        const Divider(height: 1),
                      ],
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: OutlinedButton.icon(
                          onPressed: () => _editSlot(
                            MealSlot(
                              id: 'coach_${DateTime.now().millisecondsSinceEpoch}',
                              kind: MealKind.snack,
                              minuteOfDay: 16 * 60,
                              source: MealSource.coach,
                            ),
                            isNew: true,
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(l.coachNutritionAddMeal),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ---- note ----
                SectionLabel(l.coachNutritionNote),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _note,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: l.coachNutritionNoteHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: c.sending || _slots.isEmpty ? null : _send,
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(c.sending
                      ? l.coachNutritionSending
                      : l.coachNutritionSend),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l.coachNutritionHint,
                    style:
                        context.textStyles.bodySmall?.copyWith(color: p.muted)),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
    );
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '—';
    final local = d.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}

/// Edit one meal of the plan: kind, time, name and note.
class _SlotEditor extends StatefulWidget {
  const _SlotEditor({required this.slot});

  final MealSlot slot;

  @override
  State<_SlotEditor> createState() => _SlotEditorState();
}

class _SlotEditorState extends State<_SlotEditor> {
  late MealKind _kind = widget.slot.kind;
  late int _minuteOfDay = widget.slot.minuteOfDay;
  late final TextEditingController _name =
      TextEditingController(text: widget.slot.name);
  late final TextEditingController _note =
      TextEditingController(text: widget.slot.note);

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screen,
        right: AppSpacing.screen,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.alertsEditMeal, style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<MealKind>(
            value: _kind,
            decoration: InputDecoration(labelText: l.alertsMealKind),
            items: [
              for (final k in MealKind.values)
                DropdownMenuItem(value: k, child: Text(k.localized(l))),
            ],
            onChanged: (v) => v == null ? null : setState(() => _kind = v),
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(formatMinuteOfDay(context, _minuteOfDay)),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: ReminderMath.hourOf(_minuteOfDay),
                    minute: ReminderMath.minuteOf(_minuteOfDay),
                  ),
                );
                if (picked == null) return;
                setState(() => _minuteOfDay =
                    ReminderMath.toMinuteOfDay(picked.hour, picked.minute));
              },
              child: Text(l.actionChoose),
            ),
          ),
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l.alertsMealName),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l.alertsMealNote),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(
              widget.slot.copyWith(
                kind: _kind,
                minuteOfDay: _minuteOfDay,
                name: _name.text.trim(),
                note: _note.text.trim(),
                source: MealSource.coach,
              ),
            ),
            child: Text(l.alertsSave),
          ),
        ],
      ),
    );
  }
}
