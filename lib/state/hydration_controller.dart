import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/notifications/notification_copy.dart';
import '../core/notifications/notification_service.dart';
import '../core/notifications/reminder_math.dart';
import 'profile_controller.dart';

/// Owns the water reminders: when they fire, the in-app "time to drink" prompt,
/// and the OS notification schedule. Confirming a reminder logs a glass.
///
/// By default the reminder times are *derived from the daily target* — the
/// `waterTargetGlasses` the member is aiming for (today from their profile,
/// later editable on the Meals & Drinks screen) is spread evenly across the
/// active window, so eight glasses between 8:00 and 20:00 become a reminder
/// every 90 minutes. Turning that off falls back to a plain fixed interval.
class HydrationController extends ChangeNotifier {
  HydrationController(this._profile);

  final ProfileController _profile;
  final NotificationService _notifications = NotificationService.instance;

  static const _kEnabled = 'hydration_enabled';
  static const _kDerive = 'hydration_derive_from_target';
  static const _kInterval = 'hydration_interval_hours';
  static const _kStart = 'hydration_start_hour';
  static const _kEnd = 'hydration_end_hour';

  bool _enabled = true;
  bool _deriveFromTarget = true;
  int _intervalHours = 2;
  int _startHour = 8; // 8am
  int _endHour = 20; // 8pm
  bool _permissionGranted = false;
  bool _restored = false;

  /// True when a reminder is currently awaiting the member's confirmation.
  bool _promptDue = false;

  Timer? _ticker;
  int? _lastFiredSlot; // avoid re-firing within the same slot minute
  int _lastKnownTarget = 0;

  bool get enabled => _enabled;
  bool get deriveFromTarget => _deriveFromTarget;
  int get intervalHours => _intervalHours;
  int get startHour => _startHour;
  int get endHour => _endHour;
  bool get promptDue => _promptDue;
  bool get permissionGranted => _permissionGranted;

  /// The daily goal the reminders are built from (glasses of 250 ml).
  int get targetGlasses {
    final target = _profile.member?.dailyStats.waterTargetGlasses ?? 8;
    return target <= 0 ? 8 : target;
  }

  int get glassesLogged => _profile.member?.dailyStats.waterGlasses ?? 0;

  /// Reminder times of day, in minutes since midnight.
  List<int> get slotMinutes {
    final start = ReminderMath.toMinuteOfDay(_startHour, 0);
    final end = ReminderMath.toMinuteOfDay(_endHour, 0);
    if (_deriveFromTarget) {
      return ReminderMath.spread(
        startMinutes: start,
        endMinutes: end,
        count: targetGlasses,
        maxSlots: NotificationService.capacityFor(ReminderChannel.hydration),
      );
    }
    // Guard the step: a corrupt stored value of 0 would loop forever.
    final step = (_intervalHours < 1 ? 1 : _intervalHours) * 60;
    final slots = <int>[];
    for (var m = start;
        m <= end &&
            slots.length <
                NotificationService.capacityFor(ReminderChannel.hydration);
        m += step) {
      slots.add(m);
    }
    return slots;
  }

  /// How far apart the derived reminders end up, in minutes (0 when there is
  /// only one). Shown in the Alerts screen so the cadence is not a mystery.
  int get derivedGapMinutes {
    final slots = slotMinutes;
    if (slots.length < 2) return 0;
    return slots[1] - slots[0];
  }

  Future<void> init() async {
    await _restore();
    await _notifications.init();
    // Asking here surfaces the Android 13+ prompt on first launch; on later
    // runs the platform answers from the stored grant without a dialog.
    _permissionGranted = await _notifications.requestPermission();
    _lastKnownTarget = targetGlasses;
    _profile.addListener(_onProfileChanged);
    await applySchedule();
    _startTicker();
    notifyListeners();
  }

  Future<void> _restore() async {
    if (_restored) return;
    _restored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_kEnabled) ?? _enabled;
      _deriveFromTarget = prefs.getBool(_kDerive) ?? _deriveFromTarget;
      _intervalHours = prefs.getInt(_kInterval) ?? _intervalHours;
      _startHour = prefs.getInt(_kStart) ?? _startHour;
      _endHour = prefs.getInt(_kEnd) ?? _endHour;
    } catch (_) {
      // First run or no storage — defaults are fine.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kEnabled, _enabled);
      await prefs.setBool(_kDerive, _deriveFromTarget);
      await prefs.setInt(_kInterval, _intervalHours);
      await prefs.setInt(_kStart, _startHour);
      await prefs.setInt(_kEnd, _endHour);
    } catch (_) {}
  }

  /// The daily target lives on the profile, so a change there (or, later, on
  /// the Meals & Drinks screen) has to rebuild the schedule.
  void _onProfileChanged() {
    final target = targetGlasses;
    if (target == _lastKnownTarget) return;
    _lastKnownTarget = target;
    if (_deriveFromTarget) {
      applySchedule();
      notifyListeners();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    // Check once a minute whether we've entered a reminder slot.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
  }

  void _tick() {
    if (!_enabled) return;
    final now = DateTime.now();
    final minuteOfDay = ReminderMath.nowMinuteOfDay(now);
    if (!slotMinutes.contains(minuteOfDay)) return;
    final slot = now.year * 100000000 +
        now.month * 1000000 +
        now.day * 10000 +
        minuteOfDay;
    if (slot == _lastFiredSlot) return;
    _lastFiredSlot = slot;
    _promptDue = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    if (!value) _promptDue = false;
    notifyListeners(); // reflect the switch immediately
    await _persist();
    await applySchedule();
  }

  Future<void> setDeriveFromTarget(bool value) async {
    _deriveFromTarget = value;
    notifyListeners();
    await _persist();
    await applySchedule();
  }

  Future<void> setIntervalHours(int hours) async {
    _intervalHours = hours;
    notifyListeners();
    await _persist();
    await applySchedule();
  }

  Future<void> setWindow({int? startHour, int? endHour}) async {
    if (startHour != null) _startHour = startHour;
    if (endHour != null) _endHour = endHour;
    // Keep the window sane if the two ends cross over.
    if (_endHour <= _startHour) _endHour = (_startHour + 1).clamp(1, 23);
    notifyListeners();
    await _persist();
    await applySchedule();
  }

  /// Rewrite the OS schedule from the current settings.
  Future<void> applySchedule() async {
    await _notifications.cancelChannel(ReminderChannel.hydration);
    if (!_enabled) return;
    final slots = slotMinutes;
    final total = slots.length;
    for (var i = 0; i < total; i++) {
      await _notifications.scheduleDaily(
        channel: ReminderChannel.hydration,
        slot: i,
        hour: ReminderMath.hourOf(slots[i]),
        minute: ReminderMath.minuteOf(slots[i]),
        title: NotificationCopy.waterTitle,
        body: _deriveFromTarget
            ? NotificationCopy.waterBody(i + 1, total)
            : NotificationCopy.waterBodyPlain,
        payload: 'hydration',
      );
    }
  }

  /// Member confirmed they drank water: log a glass and clear the prompt.
  Future<void> confirmDrank() async {
    _promptDue = false;
    notifyListeners();
    await _profile.logWater();
  }

  void snooze() {
    _promptDue = false;
    notifyListeners();
  }

  void dismiss() {
    _promptDue = false;
    notifyListeners();
  }

  /// Testing helpers surfaced in the Alerts screen.
  void triggerInAppPromptNow() {
    _promptDue = true;
    notifyListeners();
  }

  Future<void> sendTestNotification() => _notifications.showNow(
        channel: ReminderChannel.hydration,
        title: NotificationCopy.waterTitle,
        body: NotificationCopy.waterBodyPlain,
        payload: 'hydration',
      );

  Future<bool> requestPermission() async {
    _permissionGranted = await _notifications.requestPermission();
    notifyListeners();
    return _permissionGranted;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _profile.removeListener(_onProfileChanged);
    super.dispose();
  }
}
