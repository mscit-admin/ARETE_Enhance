import 'package:flutter/foundation.dart';

import '../data/models/auth_user.dart';
import '../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Owns the auth session and drives the AuthGate. Optional callbacks let the
/// composition root react to sign-in/out (e.g. load or clear the profile).
class AuthController extends ChangeNotifier {
  AuthController(
    this._repo, {
    Future<void> Function(AuthUser user)? onAuthenticated,
    Future<void> Function()? onSignedOut,
  })  : _onAuthenticated = onAuthenticated,
        _onSignedOut = onSignedOut;

  final AuthRepository _repo;
  final Future<void> Function(AuthUser user)? _onAuthenticated;
  final Future<void> Function()? _onSignedOut;

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;
  String? _error;
  bool _busy = false;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  String? get error => _error;
  bool get busy => _busy;

  /// Restore any persisted session on app start.
  Future<void> bootstrap() async {
    final user = await _repo.currentUser();
    if (user != null) {
      _user = user;
      _status = AuthStatus.authenticated;
      await _onAuthenticated?.call(user);
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) =>
      _run(() => _repo.signIn(email: email, password: password));

  Future<bool> signUp(String name, String email, String password,
          {String role = 'member'}) =>
      _run(() =>
          _repo.signUp(name: name, email: email, password: password, role: role));

  Future<bool> _run(Future<AuthUser> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final user = await action();
      _user = user;
      _status = AuthStatus.authenticated;
      await _onAuthenticated?.call(user);
      _busy = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
    }
    _busy = false;
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    await _onSignedOut?.call();
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}
