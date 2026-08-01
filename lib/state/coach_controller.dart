import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/mock/mock_coach.dart';
import '../data/models/coach_chat.dart';
import '../data/repositories/coach_repository.dart';
import 'profile_controller.dart' show LoadStatus;

/// Backs the member's Coach tab: the message thread and booked sessions.
class CoachController extends ChangeNotifier {
  CoachController(this._repo);

  final CoachRepository _repo;

  LoadStatus _status = LoadStatus.idle;
  final List<ChatMessage> _messages = [];
  final List<CoachSession> _sessions = [];
  bool _coachTyping = false;
  int _replyIndex = 0;
  int _seq = 0;

  LoadStatus get status => _status;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<CoachSession> get sessions => List.unmodifiable(_sessions);
  bool get coachTyping => _coachTyping;

  String _nextId() => 'local_${_seq++}';

  Future<void> load() async {
    if (_status == LoadStatus.ready) return;
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _messages
        ..clear()
        ..addAll(await _repo.getThread());
      _sessions
        ..clear()
        ..addAll(await _repo.getSessions());
      _status = LoadStatus.ready;
    } catch (_) {
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  void sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _messages.add(ChatMessage(
      id: _nextId(),
      text: trimmed,
      fromCoach: false,
      time: DateTime.now(),
    ));
    notifyListeners();
    _scheduleCoachReply();
  }

  void _scheduleCoachReply() {
    _coachTyping = true;
    notifyListeners();
    Timer(const Duration(milliseconds: 1400), () {
      _coachTyping = false;
      final reply =
          MockCoach.cannedReplies[_replyIndex % MockCoach.cannedReplies.length];
      _replyIndex++;
      _messages.add(ChatMessage(
        id: _nextId(),
        text: reply,
        fromCoach: true,
        time: DateTime.now(),
      ));
      notifyListeners();
    });
  }

  void bookSession(DateTime start, String focus, {int minutes = 45}) {
    _sessions.add(CoachSession(
      id: _nextId(),
      start: start,
      minutes: minutes,
      focus: focus,
    ));
    _messages.add(ChatMessage(
      id: _nextId(),
      text: 'Session booked',
      fromCoach: true,
      time: DateTime.now(),
      kind: MessageKind.sessionConfirmed,
    ));
    notifyListeners();
  }
}
