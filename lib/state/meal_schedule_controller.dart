import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/notifications/notification_copy.dart';
import '../core/notifications/notification_service.dart';
import '../core/notifications/reminder_math.dart';
import '../data/models/meal_slot.dart';
import '../data/models/nutrition.dart';
import '../data/repositories/nutrition_repository.dart';

/// Owns the member's fixed daily meal schedule and the reminders built from it.
///
/// The schedule is the single source of truth for both the reminders and the
/// Meals screen that will be built on top of it: that screen edits these slots
/// through [upsert]/[removeSlot], and a coach-issued nutrition plan will later
/// replace them via [replaceAll] with [MealSource.coach] — no change needed
/// here or in the scheduler.
class MealScheduleController extends ChangeNotifier {
  MealScheduleController(this._repo);

  final NutritionRepository _repo;
  final NotificationService _notifications = NotificationService.instance;

  /// Whether meal reminders fire at all is a per-device preference, so it stays
  /// in local storage; the schedule itself lives with the rest of the nutrition
  /// data and syncs to the server.
  static const _kEnabled = 'meals_reminders_enabled';

  bool _enabled = true;
  List<MealSlot> _slots = MealSlot.defaults();
  bool _restored = false;

  bool get enabled => _enabled;

  /// The schedule, always ordered by time of day.
  List<MealSlot> get slots => List.unmodifiable(_slots);

  /// Only the slots that will actually raise a reminder.
  List<MealSlot> get activeSlots => _slots.where((s) => s.enabled).toList();

  /// How many meals the schedule holds (enabled or not).
  int get mealsPerDay => _slots.length;

  /// Rebuild the schedule for [count] meals a day, spread evenly across the
  /// eating window. Names, notes and ingredients of the meals already in place
  /// are carried over in order, so changing the count keeps the member's work.
  Future<void> setMealsPerDay(
    int count, {
    int startMinutes = 7 * 60,
    int endMinutes = 21 * 60,
  }) async {
    final wanted = count.clamp(
      NutritionSettings.minMealsPerDay,
      NutritionSettings.maxMealsPerDay,
    );
    final times = ReminderMath.spread(
      startMinutes: startMinutes,
      endMinutes: endMinutes + 1, // include the closing hour as a slot
      count: wanted,
      minGapMinutes: 60,
      maxSlots: NotificationService.capacityFor(ReminderChannel.meals),
    );
    if (times.isEmpty) return;

    final previous = [..._slots];
    final next = <MealSlot>[];
    for (var i = 0; i < times.length; i++) {
      final kind = _kindFor(i, times.length, times[i]);
      final old = i < previous.length ? previous[i] : null;
      next.add(MealSlot(
        id: old?.id ?? 'meal_${i + 1}',
        kind: kind,
        minuteOfDay: times[i],
        name: old?.name ?? '',
        note: old?.note ?? '',
        items: old?.items ?? const [],
        enabled: old?.enabled ?? true,
        source: old?.source ?? MealSource.self,
      ));
    }
    await replaceAll(next);
  }

  /// Breakfast first, dinner last, lunch on the slot closest to 13:00, snacks
  /// in between — a sane default the member can override per meal.
  static MealKind _kindFor(int index, int total, int minuteOfDay) {
    if (index == 0) return MealKind.breakfast;
    if (index == total - 1) return MealKind.dinner;
    if (minuteOfDay >= 11 * 60 && minuteOfDay <= 15 * 60) return MealKind.lunch;
    return MealKind.snack;
  }

  /// The next meal due today, or null once the last one has passed.
  MealSlot? nextUpcoming([DateTime? now]) {
    final minuteOfDay = ReminderMath.nowMinuteOfDay(now);
    for (final slot in _slots) {
      if (slot.enabled && slot.minuteOfDay > minuteOfDay) return slot;
    }
    return null;
  }

  Future<void> init() async {
    await _restore();
    await applySchedule();
    notifyListeners();
  }

  Future<void> _restore() async {
    if (_restored) return;
    _restored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_kEnabled) ?? _enabled;
    } catch (_) {
      // First run — the default is fine.
    }
    await _loadSlots();
  }

  Future<void> _loadSlots() async {
    final stored = (await _repo.loadCachedSettings()).mealSchedule;
    if (stored != null && stored.isNotEmpty) _slots = [...stored];
    _sort();
  }

  /// Re-read the schedule after the nutrition data has been refreshed from the
  /// server (e.g. right after sign-in), then rebuild the reminders.
  Future<void> reloadFromStore() async {
    await _loadSlots();
    notifyListeners();
    await applySchedule();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kEnabled, _enabled);
    } catch (_) {}
    await _repo.saveMealSchedule(_slots);
  }

  void _sort() => _slots.sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    await _persist();
    await applySchedule();
  }

  /// Add a slot, or replace the one with the same id.
  Future<void> upsert(MealSlot slot) async {
    final index = _slots.indexWhere((s) => s.id == slot.id);
    if (index >= 0) {
      _slots[index] = slot;
    } else {
      _slots = [..._slots, slot];
    }
    _sort();
    notifyListeners();
    await _persist();
    await applySchedule();
  }

  Future<void> setTime(String id, int minuteOfDay) async {
    final slot = _slots.firstWhere(
      (s) => s.id == id,
      orElse: () => MealSlot(id: id, kind: MealKind.snack, minuteOfDay: minuteOfDay),
    );
    await upsert(slot.copyWith(
      minuteOfDay: minuteOfDay.clamp(0, ReminderMath.minutesPerDay - 1),
    ));
  }

  Future<void> setSlotEnabled(String id, bool value) async {
    final index = _slots.indexWhere((s) => s.id == id);
    if (index < 0) return;
    await upsert(_slots[index].copyWith(enabled: value));
  }

  Future<void> removeSlot(String id) async {
    _slots = _slots.where((s) => s.id != id).toList();
    notifyListeners();
    await _persist();
    await applySchedule();
  }

  /// Add a snack the member can then rename and re-time.
  Future<void> addSnack({int minuteOfDay = 16 * 60}) async {
    final id = 'snack_${DateTime.now().millisecondsSinceEpoch}';
    await upsert(MealSlot(
      id: id,
      kind: MealKind.snack,
      minuteOfDay: minuteOfDay.clamp(0, ReminderMath.minutesPerDay - 1),
    ));
  }

  /// Swap the whole schedule — the hook a coach-issued nutrition plan will use.
  Future<void> replaceAll(List<MealSlot> slots) async {
    _slots = [...slots];
    _sort();
    notifyListeners();
    await _persist();
    await applySchedule();
  }

  Future<void> resetToDefaults() => replaceAll(MealSlot.defaults());

  /// Rewrite the OS schedule from the current slots.
  ///
  /// The plan period lives with the nutrition settings, so it is read straight
  /// from storage here rather than mirrored into a second field: once the
  /// member's plan has run out, its meal reminders stop.
  Future<void> applySchedule() async {
    await _notifications.cancelChannel(ReminderChannel.meals);
    if (!_enabled) return;
    final settings = await _repo.loadCachedSettings();
    if (!settings.isPlanActive()) return;
    final active = activeSlots;
    final capacity = NotificationService.capacityFor(ReminderChannel.meals);
    for (var i = 0; i < active.length && i < capacity; i++) {
      final slot = active[i];
      final name = NotificationCopy.mealName(slot);
      await _notifications.scheduleDaily(
        channel: ReminderChannel.meals,
        slot: i,
        hour: slot.hour,
        minute: slot.minute,
        title: NotificationCopy.mealTitle(name),
        // What to eat is more useful than a generic nudge, so the ingredients
        // lead; the member's own note wins when they wrote one.
        body: slot.note.trim().isNotEmpty
            ? slot.note.trim()
            : (slot.itemsSummary.isNotEmpty
                ? slot.itemsSummary
                : NotificationCopy.mealBody),
        payload: 'meal:${slot.id}',
      );
    }
  }

  Future<void> sendTestNotification() {
    final slot = _slots.isEmpty ? MealSlot.defaults().first : _slots.first;
    return _notifications.showNow(
      channel: ReminderChannel.meals,
      title: NotificationCopy.mealTitle(NotificationCopy.mealName(slot)),
      body: NotificationCopy.mealBody,
      payload: 'meal:${slot.id}',
    );
  }
}
