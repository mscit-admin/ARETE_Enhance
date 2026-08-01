import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';
import '../data/models/thread_message.dart';

/// Real trainer↔member messaging over the server. Threads are keyed by the
/// peer's user id, so one controller serves both the trainee's coach chat and
/// the trainer's per-client conversations.
class MessagingController extends ChangeNotifier {
  MessagingController(this._client);

  final ApiClient _client;

  final Map<String, List<ThreadMessage>> _threads = {};
  bool _busy = false;

  bool get busy => _busy;

  List<ThreadMessage> thread(String peerId) => _threads[peerId] ?? const [];

  Future<void> load(String peerId) async {
    try {
      final j = await _client.get('/api/app/messages/$peerId')
          as Map<String, dynamic>;
      _threads[peerId] = (j['rows'] as List)
          .map((e) => ThreadMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {
      // Keep any existing messages on a transient failure.
    }
  }

  /// Send a message to [peerId]. Returns null on success, else an error.
  Future<String?> send(String peerId, String body) async {
    _busy = true;
    notifyListeners();
    try {
      final j = await _client.post(
        '/api/app/messages',
        {'toUserId': peerId, 'body': body},
        auth: true,
      ) as Map<String, dynamic>;
      final m = ThreadMessage.fromJson(j['message'] as Map<String, dynamic>);
      _threads[peerId] = [...thread(peerId), m];
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
