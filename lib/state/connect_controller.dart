import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';

/// Handles trainer↔member linking: the trainer's QR code and the member's
/// "connect a coach" action (by scanning or entering the code).
class ConnectController extends ChangeNotifier {
  ConnectController(this._client);

  final ApiClient _client;

  String? _trainerCode;
  Map<String, dynamic>? _coach;
  List<Map<String, dynamic>> _clients = [];
  bool _busy = false;

  String? get trainerCode => _trainerCode;
  Map<String, dynamic>? get coach => _coach;
  List<Map<String, dynamic>> get clients => _clients;
  bool get busy => _busy;

  /// QR payload the trainer displays and the member scans.
  String? get qrPayload =>
      _trainerCode == null ? null : 'ARETE-COACH:$_trainerCode';

  /// Drop all per-account state on sign-out so nothing leaks to the next login.
  void clear() {
    _trainerCode = null;
    _coach = null;
    _clients = [];
    _busy = false;
    notifyListeners();
  }

  /// Load (or lazily allocate) the signed-in trainer's link code.
  Future<String?> loadTrainerCode() async {
    try {
      final json = await _client.get('/api/app/trainer/code')
          as Map<String, dynamic>;
      _trainerCode = json['code'] as String?;
      notifyListeners();
      return _trainerCode;
    } catch (_) {
      return null;
    }
  }

  /// Load the signed-in trainer's linked clients.
  Future<void> loadClients() async {
    try {
      final json =
          await _client.get('/api/app/trainer/clients') as Map<String, dynamic>;
      _clients = (json['rows'] as List).cast<Map<String, dynamic>>();
      notifyListeners();
    } catch (_) {
      // Non-trainer or offline — leave the list empty.
    }
  }

  /// Load the current member's linked coach (or null).
  Future<Map<String, dynamic>?> loadCoach() async {
    try {
      final json = await _client.get('/api/app/coach') as Map<String, dynamic>;
      _coach = json['coach'] as Map<String, dynamic>?;
      notifyListeners();
      return _coach;
    } catch (_) {
      return null;
    }
  }

  /// Link the current member to a trainer by code (raw or `ARETE-COACH:CODE`).
  /// Returns null on success, or an error message.
  Future<String?> link(String code) async {
    _busy = true;
    notifyListeners();
    try {
      final json = await _client
          .post('/api/app/link', {'code': code}, auth: true) as Map<String, dynamic>;
      _coach = json['coach'] as Map<String, dynamic>?;
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
