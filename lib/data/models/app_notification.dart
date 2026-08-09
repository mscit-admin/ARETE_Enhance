/// One in-app notification (GET /api/app/notifications).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body = '',
    this.read = false,
    this.createdAt,
    this.data = const {},
  });

  final String id;
  final String type; // 'plan_assigned' | 'session_done'
  final String title;
  final String body;
  final bool read;
  final DateTime? createdAt;
  final Map<String, dynamic> data;

  AppNotification asRead() => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        read: true,
        createdAt: createdAt,
        data: data,
      );

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        type: j['type'] as String? ?? '',
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        read: j['read'] as bool? ?? false,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString())
            : null,
        data: (j['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}
