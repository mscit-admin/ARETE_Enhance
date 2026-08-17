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
  bool _weekly = false;
  List<MealSlot> _slots = MealSlot.defaults();
  bool _restored = false;

  bool get enabled => _enabled;

  /// False: one set of meals every day. True: the meals differ by weekday and
  /// the week repeats.
  bool get weekly => _weekly;

  /// The schedule, always ordered by time of day.
  List<MealSlot> get slots => List.unmodifiable(_slots);

  /// Only the slots that will actually raise a reminder.
  List<MealSlot> get activeSlots => _slots.where((s) => s.enabled).toList();

  /// The meals that apply on [weekday] (`DateTime.monday` = 1), in time order.
  List<MealSlot> slotsFor(int weekday) =>
      [for (final s in _slots) if (s.appliesOn(weekday)) s];

  /// Today's meals — what the screen shows and what gets ticked off.
  List<MealSlot> slotsToday([DateTime? now]) =>
      slotsFor((now ?? DateTime.now()).weekday);

  /// How many meals a given day holds (all days are alike unless [weekly]).
  int mealsOn(int weekday) => slotsFor(weekday).length;

  /// How many meals the schedule holds for today.
  int get mealsPerDay => _weekly ? mealsOn(DateTime.now().weekday) : _slots.length;

  /// Switch between one repeated day and a week that varies.
  ///
  /// Nothing is thrown away either way: slots keep their days, and a slot with
  /// no days set already means "every day", so turning the week off simply
  /// stops the app filtering by weekday.
  Future<void> setWeekly(bool value) async {
    if (_weekly == value) return;
    _weekly = value;
    notifyListeners();
    await _persist();
    await applySchedule();
  }

  /// Copy every meal of [from] onto [to], replacing whatever those days held.
  /// This is how a member fills a week from one day they already like.
  Future<void> copyDay(int from, Set<int> to) async {
    final targets = to.where((d) => d != from).toSet();
    if (targets.isEmpty) return;
    final source = slotsFor(from);
    if (source.isEmpty) return;

    // Clear the target days out of every existing meal; one left with no day
    // at all was only on the days being overwritten, so it goes.
    final kept = <MealSlot>[];
    for (final slot in _slots) {
      final effective =
          slot.everyDay ? MealSlot.allWeekdays.toSet() : slot.days;
      final remaining = effective.where((d) => !targets.contains(d)).toSet();
      if (remaining.isNotEmpty) kept.add(slot.copyWith(days: remaining));
    }
    // Then lay the source day's meals over them, each copy with its own id so
    // ticking one off does not tick the original.
    final stamp = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < source.length; i++) {
      kept.add(source[i].withId('copy_${stamp}_$i').copyWith(days: targets));
    }
    await replaceAll(kept);
  }

  /// Rebuild the schedule for [count] meals a day, spread evenly across the
  /// eating window. Names, notes and ingredients of the meals already in place
  /// are carried over in order, so changing the count keeps the member's work.
  Future<void> setMealsPerDay(
    int count, {
    int startMinutes = 7 * 60,
    int endMinutes = 21 * 60,
    int? weekday,
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

    // Weekly plans regenerate one day and leave the rest of the week alone.
    final day = _weekly ? (weekday ?? DateTime.now().weekday) : null;
    final previous = day == null ? [..._slots] : slotsFor(day);
    final untouched = day == null
        ? <MealSlot>[]
        : [
            for (final slot in _slots)
              if (!slot.appliesOn(day))
                slot
              else if (slot.everyDay)
                // A meal that ran all week keeps the other six days.
                slot.copyWith(
                    days: MealSlot.allWeekdays.where((d) => d != day).toSet())
              else if (slot.days.length > 1)
                slot.copyWith(days: slot.days.where((d) => d != day).toSet()),
          ];

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final next = <MealSlot>[...untouched];
    for (var i = 0; i < times.length; i++) {
      final old = i < previous.length ? previous[i] : null;
      next.add(MealSlot(
        id: old?.id ?? (day == null ? 'meal_${i + 1}' : 'meal_${stamp}_$i'),
        kind: _kindFor(i, times.length, times[i]),
        minuteOfDay: times[i],
        name: old?.name ?? '',
        note: old?.note ?? '',
        items: old?.items ?? const [],
        enabled: old?.enabled ?? true,
        source: old?.source ?? MealSource.self,
        days: day == null ? const {} : {day},
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
    for (final slot in slotsToday(now)) {
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
    final settings = await _repo.loadCachedSettings();
    _weekly = settings.weeklyMeals;
    final stored = settings.mealSchedule;
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
    await _repo.saveMealSchedule(_slots, weeklyMeals: _weekly);
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

  /// Add a snack the member can then rename and re-time. On a weekly plan the
  /// caller passes the day it belongs to; an empty set means every day.
  Future<void> addSnack({
    int minuteOfDay = 16 * 60,
    Set<int> days = const {},
  }) async {
    final id = 'snack_${DateTime.now().millisecondsSinceEpoch}';
    await upsert(MealSlot(
      id: id,
      kind: MealKind.snack,
      minuteOfDay: minuteOfDay.clamp(0, ReminderMath.minutesPerDay - 1),
      days: days,
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
    final capacity = NotificationService.capacityFor(ReminderChannel.meals);
    var index = 0;

    if (!_weekly) {
      for (final slot in activeSlots) {
        if (index >= capacity) break;
        await _notifications.scheduleDaily(
          channel: ReminderChannel.meals,
          slot: index++,
          hour: slot.hour,
          minute: slot.minute,
          title: NotificationCopy.mealTitle(NotificationCopy.mealName(slot)),
          body: _bodyFor(slot),
          payload: 'meal:${slot.id}',
        );
      }
      return;
    }

    // A week that varies needs one scheduled reminder per meal *per weekday*.
    for (final weekday in MealSlot.allWeekdays) {
      for (final slot in slotsFor(weekday)) {
        if (!slot.enabled) continue;
        if (index >= capacity) return;
        await _notifications.scheduleWeekly(
          channel: ReminderChannel.meals,
          slot: index++,
          weekday: weekday,
          hour: slot.hour,
          minute: slot.minute,
          title: NotificationCopy.mealTitle(NotificationCopy.mealName(slot)),
          body: _bodyFor(slot),
          payload: 'meal:${slot.id}',
        );
      }
    }
  }

  /// What to eat is more useful than a generic nudge, so the ingredients lead;
  /// the member's own note wins when they wrote one.
  static String _bodyFor(MealSlot slot) {
    if (slot.note.trim().isNotEmpty) return slot.note.trim();
    if (slot.itemsSummary.isNotEmpty) return slot.itemsSummary;
    return NotificationCopy.mealBody;
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
