import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/notifications/notification_copy.dart';
import '../core/notifications/notification_service.dart';
import '../core/notifications/reminder_math.dart';
import '../data/models/fitness_tip.dart';
import '../data/tips/fitness_tips.dart';

/// Owns the fitness tips: which day shows which tip, the daily tip
/// notification, and the card on the home screen.
///
/// Tips are bundled content, so this controller needs neither the network nor
/// any other screen — it stands entirely on its own.
class TipsController extends ChangeNotifier {
  TipsController();

  final NotificationService _notifications = NotificationService.instance;

  static const _kEnabled = 'tips_enabled';
  static const _kMinute = 'tips_minute_of_day';
  static const _kMuted = 'tips_muted_categories';
  static const _kDismissed = 'tips_dismissed_day';

  /// How many days of tips are queued with the OS. They are one-shots (each day
  /// has different text), so they run out if the app is not opened for a week —
  /// every launch tops the queue back up.
  static const int queuedDays = 7;

  bool _enabled = true;
  int _minuteOfDay = 9 * 60; // 9:00
  Set<TipCategory> _muted = <TipCategory>{};
  String _dismissedDay = '';
  bool _restored = false;

  bool get enabled => _enabled;
  int get minuteOfDay => _minuteOfDay;
  int get hour => ReminderMath.hourOf(_minuteOfDay);
  int get minute => ReminderMath.minuteOf(_minuteOfDay);
  Set<TipCategory> get mutedCategories => Set.unmodifiable(_muted);

  /// The categories tips are drawn from (everything that is not muted).
  Set<TipCategory> get activeCategories =>
      TipCategory.values.where((c) => !_muted.contains(c)).toSet();

  bool isMuted(TipCategory category) => _muted.contains(category);

  /// Today's tip, honouring the muted categories.
  FitnessTip get tipOfDay =>
      FitnessTips.tipForDay(DateTime.now(), categories: activeCategories);

  /// Today's tip text in the app's current language.
  String get tipOfDayText => tipOfDay.localized(NotificationCopy.localeCode);

  /// Whether the home-screen card should be shown (it hides once dismissed,
  /// and comes back with tomorrow's tip).
  bool get showCard => _dismissedDay != _dayKey(DateTime.now());

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
      _minuteOfDay = prefs.getInt(_kMinute) ?? _minuteOfDay;
      _dismissedDay = prefs.getString(_kDismissed) ?? '';
      final muted = prefs.getStringList(_kMuted) ?? const <String>[];
      _muted = {
        for (final name in muted) ...TipCategory.values.where((c) => c.name == name),
      };
    } catch (_) {
      // Defaults are fine.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kEnabled, _enabled);
      await prefs.setInt(_kMinute, _minuteOfDay);
      await prefs.setString(_kDismissed, _dismissedDay);
      await prefs.setStringList(_kMuted, [for (final c in _muted) c.name]);
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    await _persist();
    await applySchedule();
  }

  Future<void> setTime(int minuteOfDay) async {
    _minuteOfDay = minuteOfDay.clamp(0, ReminderMath.minutesPerDay - 1);
    notifyListeners();
    await _persist();
    await applySchedule();
  }

  Future<void> setCategoryMuted(TipCategory category, bool muted) async {
    final next = {..._muted};
    if (muted) {
      next.add(category);
    } else {
      next.remove(category);
    }
    // Muting everything would leave nothing to show; keep the last one on.
    if (next.length >= TipCategory.values.length) return;
    _muted = next;
    notifyListeners();
    await _persist();
    await applySchedule();
  }

  /// Hide today's card; tomorrow's tip brings it back.
  Future<void> dismissToday() async {
    _dismissedDay = _dayKey(DateTime.now());
    notifyListeners();
    await _persist();
  }

  /// Queue the next [queuedDays] tips with the OS.
  Future<void> applySchedule() async {
    await _notifications.cancelChannel(ReminderChannel.tips);
    if (!_enabled) return;
    final now = DateTime.now();
    final categories = activeCategories;
    for (var i = 0; i < queuedDays; i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      final when = DateTime(day.year, day.month, day.day, hour, minute);
      if (!when.isAfter(now)) continue; // today's slot already passed
      final tip = FitnessTips.tipForDay(day, categories: categories);
      await _notifications.scheduleOnce(
        channel: ReminderChannel.tips,
        slot: i,
        when: when,
        title: NotificationCopy.tipTitle,
        body: tip.localized(NotificationCopy.localeCode),
        payload: 'tip:${tip.id}',
      );
    }
  }

  Future<void> sendTestNotification() => _notifications.showNow(
        channel: ReminderChannel.tips,
        title: NotificationCopy.tipTitle,
        body: tipOfDayText,
        payload: 'tip:${tipOfDay.id}',
      );

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
