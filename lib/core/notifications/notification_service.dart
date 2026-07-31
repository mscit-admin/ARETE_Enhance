import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around flutter_local_notifications for hydration reminders.
///
/// Uses inexact periodic scheduling (no exact-alarm permission needed) so it
/// works on Android 12+ without special approval. No-ops on web.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _channelId = 'hydration';
  static const String _channelName = 'Hydration reminders';
  static const int _periodicId = 1001;
  static const int _instantId = 1002;

  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Reminders to drink water during the day',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
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

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Reminders to drink water during the day',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

  /// Fire a reminder immediately (used by the "Send test notification" button).
  Future<void> showNow() async {
    if (kIsWeb) return;
    await init();
    await _plugin.show(
      _instantId,
      'Time to hydrate 💧',
      'Drink a glass of water and log it in ARETE.',
      _details,
    );
  }

  /// Repeat a reminder every [interval] (inexact, battery-friendly).
  Future<void> scheduleEvery(Duration interval) async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancel(_periodicId);
    await _plugin.periodicallyShowWithDuration(
      _periodicId,
      'Time to hydrate 💧',
      'Drink a glass of water and log it in ARETE.',
      interval,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelReminders() async {
    if (kIsWeb) return;
    await _plugin.cancel(_periodicId);
  }
}
