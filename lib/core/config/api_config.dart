import 'dart:convert';

/// Backend location for the app.
///
/// The base URL is **hard-coded and obfuscated** (XOR + base64) so it does not
/// appear in a plain `strings` scan of the APK. Note: obfuscation is not real
/// encryption — a determined attacker can still recover it, since the key ships
/// with the app. Real transport security comes from HTTPS (planned).
///
/// To change the server address later, regenerate [_encoded] for the new URL
/// with the same [_key] (see admin/README or the build notes), e.g. switching
/// `http://161.97.78.116:2955` to `https://api.yourdomain.com`.
class ApiConfig {
  ApiConfig._();

  // XOR key used to obfuscate the base URL.
  static const List<int> _key = [
    0x5A, 0x3C, 0x7E, 0x11, 0x2D, 0x69, 0x84, 0xB3,
  ];

  // base64( XOR( "http://161.97.78.116:2955", _key ) )
  static const String _encoded = 'MkgKYRdGq4JsDVAoGkezi3QNTycXW72Gbw==';

  static String? _cached;

  /// The decoded backend base URL, e.g. `http://161.97.78.116:2955`.
  static String get baseUrl {
    final cached = _cached;
    if (cached != null) return cached;
    final bytes = base64.decode(_encoded);
    final out = List<int>.generate(
      bytes.length,
      (i) => bytes[i] ^ _key[i % _key.length],
    );
    return _cached = utf8.decode(out);
  }

  /// Full URL for an API path (e.g. `/api/app/auth/login`).
  static Uri uri(String path) => Uri.parse('$baseUrl$path');

  /// Network timeout for API calls.
  static const Duration timeout = Duration(seconds: 15);
}
