import '../models/coach_chat.dart';

/// Seeded coach conversation and sessions for the local-first build.
class MockCoach {
  MockCoach._();

  static final DateTime _base = DateTime(2026, 7, 30, 9, 0);

  static List<ChatMessage> thread() => [
        ChatMessage(
          id: 'm1',
          text: 'Great push session 💪 Bumped your bench target to 62.5kg '
              'next week.',
          fromCoach: true,
          time: _base,
        ),
        ChatMessage(
          id: 'm2',
          text: 'New program assigned',
          fromCoach: true,
          time: _base.add(const Duration(minutes: 1)),
          kind: MessageKind.planCard,
          planName: 'Lower Day B',
        ),
        ChatMessage(
          id: 'm3',
          text: 'Felt strong today. Left knee was a bit tight on squats.',
          fromCoach: false,
          time: _base.add(const Duration(hours: 2)),
        ),
        ChatMessage(
          id: 'm4',
          text: 'Noted — let\'s swap to leg press this week. Book a check-in '
              'when you can.',
          fromCoach: true,
          time: _base.add(const Duration(hours: 2, minutes: 5)),
        ),
      ];

  static List<CoachSession> sessions() => [
        CoachSession(
          id: 's1',
          start: DateTime(2026, 8, 4, 18, 0),
          minutes: 45,
          focus: 'Form check · Lower body',
        ),
      ];

  /// Canned coach replies cycled through when the member sends a message.
  static const List<String> cannedReplies = [
    'Got it 👍 Keep the reps controlled.',
    'Nice work — log it and I\'ll review tonight.',
    'Let\'s push the top set 2.5kg next time.',
    'Great. Hydrate and get some protein in.',
  ];
}
