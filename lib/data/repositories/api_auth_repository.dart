import '../api/api_client.dart';
import '../models/auth_user.dart';
import 'auth_repository.dart';

/// Auth backed by the ARETE server (`/api/app/auth/*`). The JWT is stored by
/// [ApiClient]; the profile is fetched separately by the profile repository.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client);

  final ApiClient _client;

  AuthUser _userFromProfile(Map<String, dynamic> p) => AuthUser(
        id: p['id'] as String,
        name: p['fullName'] as String,
        email: p['email'] as String,
        role: (p['role'] as String?) ?? 'member',
      );

  @override
  Future<AuthUser?> currentUser() async {
    final token = await _client.loadToken();
    if (token == null) return null;
    try {
      final json = await _client.get('/api/app/profile');
      return _userFromProfile(json as Map<String, dynamic>);
    } catch (_) {
      // Expired token or server unreachable — treat as signed out.
      return null;
    }
  }

  @override
  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
    String role = 'member',
  }) async {
    try {
      final json = await _client.post(
        '/api/app/auth/register',
        {'name': name, 'email': email, 'password': password, 'role': role},
      ) as Map<String, dynamic>;
      await _client.setToken(json['token'] as String);
      return _userFromProfile(json['profile'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final json = await _client.post(
        '/api/app/auth/login',
        {'email': email, 'password': password},
      ) as Map<String, dynamic>;
      await _client.setToken(json['token'] as String);
      return _userFromProfile(json['profile'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> signOut() => _client.setToken(null);
}
