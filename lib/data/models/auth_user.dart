/// A signed-in account (identity + role; profile details live in Member).
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'member',
  });

  final String id;
  final String name;
  final String email;

  /// 'member' or 'trainer' (admins use the web console).
  final String role;

  bool get isTrainer => role == 'trainer';

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'email': email, 'role': role};

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: (json['role'] as String?) ?? 'member',
      );
}

/// Thrown for expected auth failures (bad credentials, duplicate email…).
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
