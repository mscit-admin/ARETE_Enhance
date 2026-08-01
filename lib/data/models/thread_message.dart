/// A single message in a trainer↔member conversation, as returned by the
/// server. `planCard` messages carry a [planId] for a plan hand-off.
class ThreadMessage {
  const ThreadMessage({
    required this.id,
    required this.fromCoach,
    required this.body,
    this.kind = 'text',
    this.planId,
    this.createdAt,
  });

  final String id;
  final bool fromCoach;
  final String body;
  final String kind;
  final String? planId;
  final DateTime? createdAt;

  bool get isPlanCard => kind == 'planCard';

  factory ThreadMessage.fromJson(Map<String, dynamic> j) => ThreadMessage(
        id: j['id'] as String,
        fromCoach: j['fromCoach'] as bool? ?? false,
        body: j['body'] as String? ?? '',
        kind: j['kind'] as String? ?? 'text',
        planId: j['planId'] as String?,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'] as String)
            : null,
      );
}
