import 'package:arete/data/models/coach_chat.dart';
import 'package:arete/data/repositories/mock_coach_repository.dart';
import 'package:arete/state/coach_controller.dart';
import 'package:arete/state/profile_controller.dart' show LoadStatus;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads the seeded thread and sessions', () async {
    final c = CoachController(MockCoachRepository());
    await c.load();
    expect(c.status, LoadStatus.ready);
    expect(c.messages, isNotEmpty);
    expect(c.messages.any((m) => m.kind == MessageKind.planCard), isTrue);
    expect(c.sessions, isNotEmpty);
  });

  test('booking a session adds it plus a confirmation message', () async {
    final c = CoachController(MockCoachRepository());
    await c.load();
    final before = c.sessions.length;

    c.bookSession(DateTime(2026, 9, 1, 18, 0), 'Form check');

    expect(c.sessions.length, before + 1);
    expect(c.messages.last.kind, MessageKind.sessionConfirmed);
  });
}
