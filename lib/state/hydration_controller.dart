import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/notifications/notification_service.dart';
import 'profile_controller.dart';

/// Owns hydration-reminder settings, the in-app "time to drink" prompt, and the
/// OS notification schedule. Confirming a reminder logs a glass of water.
class HydrationController extends ChangeNotifier {
  HydrationController(this._profile);

  final ProfileController _profile;
  final NotificationService _notifications = NotificationService.instance;

  bool _enabled = true;
  int _intervalHours = 2;
  int _startHour = 8; // 8am
  int _endHour = 20; // 8pm
  bool _permissionGranted = false;

  /// True when a reminder is currently awaiting the member's confirmation.
  bool _promptDue = false;

  Timer? _ticker;
  int? _lastFiredSlot; // avoid re-firing within the same slot minute

  bool get enabled => _enabled;
  int get intervalHours => _intervalHours;
  int get startHour => _startHour;
  int get endHour => _endHour;
  bool get promptDue => _promptDue;
  bool get permissionGranted => _permissionGranted;

  /// Reminder times of day derived from the interval + window (e.g. 8,10,…,20).
  List<int> get slotHours {
    final slots = <int>[];
    for (var h = _startHour; h <= _endHour; h += _intervalHours) {
      slots.add(h);
    }
    return slots;
  }

  Future<void> init() async {
    await _notifications.init();
    _permissionGranted = await _notifications.requestPermission();
    await _applySchedule();
    _startTicker();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    // Check once a minute whether we've entered a reminder slot.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
  }

  void _tick() {
    if (!_enabled) return;
    final now = DateTime.now();
    if (now.minute != 0) return;
    if (!slotHours.contains(now.hour)) return;
    final slot = now.year * 1000000 + now.month * 10000 + now.day * 100 + now.hour;
    if (slot == _lastFiredSlot) return;
    _lastFiredSlot = slot;
    _promptDue = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    if (!value) _promptDue = false;
    await _applySchedule();
    notifyListeners();
  }

  Future<void> setIntervalHours(int hours) async {
    _intervalHours = hours;
    await _applySchedule();
    notifyListeners();
  }

  Future<void> setWindow({int? startHour, int? endHour}) async {
    if (startHour != null) _startHour = startHour;
    if (endHour != null) _endHour = endHour;
    await _applySchedule();
    notifyListeners();
  }

  Future<void> _applySchedule() async {
    if (_enabled) {
      await _notifications.scheduleEvery(Duration(hours: _intervalHours));
    } else {
      await _notifications.cancelReminders();
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

  /// Testing helpers surfaced in Settings.
  void triggerInAppPromptNow() {
    _promptDue = true;
    notifyListeners();
  }

  Future<void> sendTestNotification() => _notifications.showNow();

  Future<bool> requestPermission() async {
    _permissionGranted = await _notifications.requestPermission();
    notifyListeners();
    return _permissionGranted;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
