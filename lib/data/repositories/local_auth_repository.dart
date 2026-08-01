import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';
import 'auth_repository.dart';

/// Auth backed by on-device storage (shared_preferences). Accounts and the
/// active session survive app restarts. Passwords are stored only as salted
/// SHA-256 hashes — never in clear text.
///
/// This is a stand-in for a real backend; the same [AuthRepository] contract is
/// what a Firebase/REST implementation would satisfy.
class LocalAuthRepository implements AuthRepository {
  static const _accountsKey = 'auth_accounts_v1';
  static const _sessionKey = 'auth_session_v1';
  static const _salt = 'arete_local_salt_v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  String _hash(String password) =>
      sha256.convert(utf8.encode('$_salt:$password')).toString();

  String _normalize(String email) => email.trim().toLowerCase();

  Future<Map<String, dynamic>> _accounts(SharedPreferences p) async {
    final raw = p.getString(_accountsKey);
    if (raw == null) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<AuthUser?> currentUser() async {
    final p = await _prefs;
    final sessionEmail = p.getString(_sessionKey);
    if (sessionEmail == null) return null;
    final accounts = await _accounts(p);
    final acc = accounts[sessionEmail] as Map<String, dynamic>?;
    if (acc == null) return null;
    return AuthUser(
        id: sessionEmail, name: acc['name'] as String, email: sessionEmail);
  }

  @override
  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final p = await _prefs;
    final key = _normalize(email);
    final accounts = await _accounts(p);
    if (accounts.containsKey(key)) {
      throw const AuthException('That email is already registered.');
    }
    accounts[key] = {'name': name.trim(), 'password': _hash(password)};
    await p.setString(_accountsKey, jsonEncode(accounts));
    await p.setString(_sessionKey, key);
    return AuthUser(id: key, name: name.trim(), email: key);
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final p = await _prefs;
    final key = _normalize(email);
    final accounts = await _accounts(p);
    final acc = accounts[key] as Map<String, dynamic>?;
    if (acc == null) {
      throw const AuthException('No account found for that email.');
    }
    if (acc['password'] != _hash(password)) {
      throw const AuthException('Incorrect password.');
    }
    await p.setString(_sessionKey, key);
    return AuthUser(id: key, name: acc['name'] as String, email: key);
  }

  @override
  Future<void> signOut() async {
    final p = await _prefs;
    await p.remove(_sessionKey);
  }
}
