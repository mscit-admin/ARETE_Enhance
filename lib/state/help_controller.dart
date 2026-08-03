import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the first-run app guide (the in-app assistant) has been
/// shown yet. The guide auto-opens once after install, then stays hidden until
/// the member replays it from the account menu.
class HelpController extends ChangeNotifier {
  HelpController() {
    _restore();
  }

  static const _seenKey = 'help_intro_seen_v1';

  bool _loaded = false;
  bool _seen = false;

  /// True once the stored flag has been read from disk.
  bool get loaded => _loaded;

  /// True after the intro guide has been completed or skipped at least once.
  bool get hasSeenIntro => _seen;

  /// True when the intro should pop up automatically (fresh install).
  bool get shouldAutoShow => _loaded && !_seen;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    _seen = prefs.getBool(_seenKey) ?? false;
    _loaded = true;
    notifyListeners();
  }

  /// Persist that the member has now seen the intro guide.
  Future<void> markIntroSeen() async {
    if (_seen) return;
    _seen = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }
}
