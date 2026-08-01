/// The kind of content a chat message carries.
enum MessageKind { text, planCard, sessionConfirmed }

/// A single message in the member ↔ coach thread.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.fromCoach,
    required this.time,
    this.kind = MessageKind.text,
    this.planName,
  });

  final String id;
  final String text;

  /// True if sent by the coach, false if sent by the member.
  final bool fromCoach;
  final DateTime time;
  final MessageKind kind;

  /// Set when [kind] is [MessageKind.planCard].
  final String? planName;
}

/// A booked one-on-one coaching session.
class CoachSession {
  const CoachSession({
    required this.id,
    required this.start,
    required this.minutes,
    required this.focus,
  });

  final String id;
  final DateTime start;
  final int minutes;
  final String focus;
}
