import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';
import '../data/models/app_notification.dart';

/// Loads the signed-in user's in-app notifications and the unread count.
class NotificationsController extends ChangeNotifier {
  NotificationsController(this._client);

  final ApiClient _client;

  List<AppNotification> _items = [];
  int _unread = 0;
  bool _loaded = false;

  List<AppNotification> get items => _items;
  int get unread => _unread < 0 ? 0 : _unread;
  bool get loaded => _loaded;

  Future<void> load() async {
    try {
      final j =
          await _client.get('/api/app/notifications') as Map<String, dynamic>;
      _items = (j['rows'] as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      _unread = (j['unread'] as num?)?.toInt() ?? 0;
    } catch (_) {
      // Offline or unmigrated — keep whatever we had.
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// Mark everything read (optimistically), then tell the server.
  Future<void> markAllRead() async {
    if (_unread == 0 && _items.every((n) => n.read)) return;
    _unread = 0;
    _items = [for (final n in _items) n.read ? n : n.asRead()];
    notifyListeners();
    try {
      await _client.post('/api/app/notifications/read', {}, auth: true);
    } catch (_) {}
  }

  void clear() {
    _items = [];
    _unread = 0;
    _loaded = false;
    notifyListeners();
  }
}
