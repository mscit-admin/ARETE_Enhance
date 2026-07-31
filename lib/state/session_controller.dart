import 'package:flutter/foundation.dart';

import '../core/constants/enums.dart';

/// Holds app-wide session state: the active role and theme mode.
///
/// Phase 1 uses one app with role switching (member ↔ trainer). A real build
/// would derive the available roles from the authenticated account.
class SessionController extends ChangeNotifier {
  UserRole _role = UserRole.member;
  bool _followSystemTheme = true;
  bool _darkOverride = false;

  UserRole get role => _role;
  bool get isTrainer => _role == UserRole.trainer;

  void setRole(UserRole role) {
    if (_role == role) return;
    _role = role;
    notifyListeners();
  }

  void toggleRole() {
    _role = _role == UserRole.member ? UserRole.trainer : UserRole.member;
    notifyListeners();
  }

  // Theme
  bool get followSystemTheme => _followSystemTheme;
  bool get isDark => _darkOverride;

  void setFollowSystemTheme(bool value) {
    _followSystemTheme = value;
    notifyListeners();
  }

  void setDark(bool value) {
    _followSystemTheme = false;
    _darkOverride = value;
    notifyListeners();
  }
}
