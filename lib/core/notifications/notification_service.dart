import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// The kinds of reminder ARETE can raise. Each maps to its own Android
/// notification channel so the member can silence one without losing the
/// others, and to its own block of notification ids.
enum ReminderChannel { hydration, meals, tips }

/// Shared wrapper around flutter_local_notifications.
///
/// Everything is scheduled as a *daily* notification at a fixed time of day
/// (`zonedSchedule` + `DateTimeComponents.time`), which is what both the water
/// reminders (derived from the daily target) and the meal schedule need.
///
/// Scheduling is inexact (`inexactAllowWhileIdle`) on purpose: exact alarms
/// need the `SCHEDULE_EXACT_ALARM` approval on Android 12+, and a reminder that
/// lands a few minutes late is perfectly acceptable here.
///
/// No-ops on web.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _timeZonesReady = false;

  /// Id blocks — one per channel, so a channel can be rescheduled or cleared
  /// without touching the others.
  static const int _hydrationBaseId = 1000;
  static const int _mealsBaseId = 1100;
  static const int _tipsBaseId = 1200;
  static const int _instantId = 1900;

  /// How many distinct daily slots each channel may hold.
  static const Map<ReminderChannel, int> _capacity = {
    ReminderChannel.hydration: 24,
    ReminderChannel.meals: 12,
    // A week of tips: each day carries different text, so they are queued as
    // one-shots rather than a single repeating notification.
    ReminderChannel.tips: 7,
  };

  /// Called with the notification payload when the member taps a reminder.
  /// The app sets this to route into the right screen; unset it on teardown.
  static void Function(String payload)? onSelect;

  static int baseIdFor(ReminderChannel channel) => switch (channel) {
        ReminderChannel.hydration => _hydrationBaseId,
        ReminderChannel.meals => _mealsBaseId,
        ReminderChannel.tips => _tipsBaseId,
      };

  static int capacityFor(ReminderChannel channel) => _capacity[channel] ?? 1;

  static String channelId(ReminderChannel channel) => switch (channel) {
        ReminderChannel.hydration => 'hydration',
        ReminderChannel.meals => 'meals',
        ReminderChannel.tips => 'tips',
      };

  static String _channelName(ReminderChannel channel) => switch (channel) {
        ReminderChannel.hydration => 'Hydration reminders',
        ReminderChannel.meals => 'Meal reminders',
        ReminderChannel.tips => 'Fitness tips',
      };

  static String _channelDescription(ReminderChannel channel) =>
      switch (channel) {
        ReminderChannel.hydration =>
          'Reminders to drink water during the day',
        ReminderChannel.meals => 'Reminders for the meals on your schedule',
        ReminderChannel.tips => 'A short training tip once a day',
      };

  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) onSelect?.call(payload);
      },
    );

    final android13 = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    for (final channel in ReminderChannel.values) {
      await android13?.createNotificationChannel(
        AndroidNotificationChannel(
          channelId(channel),
          _channelName(channel),
          description: _channelDescription(channel),
          importance: Importance.high,
        ),
      );
    }

    _initTimeZones();
    _initialized = true;
  }

  /// The timezone database backs `zonedSchedule`. We deliberately leave
  /// `tz.local` at its default (UTC) and convert wall-clock times with
  /// `TZDateTime.from`, which preserves the *instant* — so a reminder set for
  /// 8:00 local fires at 8:00 local without needing a platform channel to
  /// discover the device's IANA zone name. A daylight-saving change can shift
  /// a repeat by an hour; every schedule is rebuilt on app start, which
  /// corrects it.
  void _initTimeZones() {
    if (_timeZonesReady) return;
    tzdata.initializeTimeZones();
    _timeZonesReady = true;
  }

  /// Ask for the Android 13+ POST_NOTIFICATIONS runtime permission.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  NotificationDetails _detailsFor(ReminderChannel channel) => NotificationDetails(
        android: AndroidNotificationDetails(
          channelId(channel),
          _channelName(channel),
          channelDescription: _channelDescription(channel),
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

  /// Fire a reminder immediately (the "send a test" buttons).
  Future<void> showNow({
    required ReminderChannel channel,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    await init();
    await _plugin.show(
      _instantId,
      title,
      body,
      _detailsFor(channel),
      payload: payload,
    );
  }

  /// Schedule (or replace) the [slot]-th daily reminder of [channel] at
  /// [hour]:[minute]. Slots are indexed from 0 and bounded by the channel's
  /// capacity.
  Future<void> scheduleDaily({
    required ReminderChannel channel,
    required int slot,
    required int hour,
    required int minute,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    if (slot < 0 || slot >= capacityFor(channel)) return;
    await init();
    await _plugin.zonedSchedule(
      baseIdFor(channel) + slot,
      title,
      body,
      _nextInstanceOf(hour, minute),
      _detailsFor(channel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// Schedule a one-shot notification at an absolute [when]. Used where the
  /// text differs from day to day (the daily tip), which a repeating schedule
  /// cannot express. Times already in the past are skipped.
  Future<void> scheduleOnce({
    required ReminderChannel channel,
    required int slot,
    required DateTime when,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    if (slot < 0 || slot >= capacityFor(channel)) return;
    if (!when.isAfter(DateTime.now())) return;
    await init();
    _initTimeZones();
    await _plugin.zonedSchedule(
      baseIdFor(channel) + slot,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      _detailsFor(channel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Drop every scheduled reminder belonging to [channel].
  Future<void> cancelChannel(ReminderChannel channel) async {
    if (kIsWeb) return;
    final base = baseIdFor(channel);
    for (var i = 0; i < capacityFor(channel); i++) {
      await _plugin.cancel(base + i);
    }
  }

  /// The next occurrence of [hour]:[minute] in the device's local time,
  /// expressed as the equivalent instant for the scheduler.
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    _initTimeZones();
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute);
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }
    return tz.TZDateTime.from(target, tz.local);
  }
}
