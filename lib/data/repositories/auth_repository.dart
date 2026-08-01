import '../models/auth_user.dart';

/// Abstraction over authentication. The UI depends only on this, so the local
/// implementation can be swapped for Firebase Auth or a REST API later.
abstract class AuthRepository {
  /// The currently signed-in user, restored from storage, or null.
  Future<AuthUser?> currentUser();

  /// Create an account and sign in. Throws [AuthException] on failure.
  /// [role] is 'member' or 'trainer'.
  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
    String role = 'member',
  });

  /// Sign in with existing credentials. Throws [AuthException] on failure.
  Future<AuthUser> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
