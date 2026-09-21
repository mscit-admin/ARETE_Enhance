import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Details of an available app update.
class UpdateInfo {
  const UpdateInfo({
    required this.currentBuild,
    required this.latestBuild,
    required this.versionName,
    required this.downloadUrl,
    this.notes = '',
  });

  final int currentBuild;
  final int latestBuild;
  final String versionName;
  final String downloadUrl;
  final String notes;
}

/// Checks GitHub Releases for a newer APK and returns a direct download link.
/// The repository is public, so this is an unauthenticated read. The CI
/// publishes a release per build, tagged `v<buildNumber>`, with the APK
/// attached — so a higher build number than the installed one means an update.
class UpdateService {
  UpdateService({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  static const _owner = 'mscit-admin';
  static const _repo = 'ARETE_Enhance';

  Uri get _latestUri =>
      Uri.parse('https://api.github.com/repos/$_owner/$_repo/releases/latest');

  /// Returns update info if a newer build is available, else null.
  /// Never throws — a network/parse failure just means "no update offered".
  Future<UpdateInfo?> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;

      final res = await _http
          .get(_latestUri, headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;

      final tag = (json['tag_name'] as String?) ?? '';
      final latestBuild =
          int.tryParse(tag.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (latestBuild <= currentBuild) return null;

      // Find the APK asset's direct download URL.
      final assets = (json['assets'] as List?) ?? const [];
      String? apkUrl;
      for (final a in assets) {
        final m = a as Map<String, dynamic>;
        final name = (m['name'] as String?) ?? '';
        if (name.toLowerCase().endsWith('.apk')) {
          apkUrl = m['browser_download_url'] as String?;
          break;
        }
      }
      if (apkUrl == null || apkUrl.isEmpty) return null;

      return UpdateInfo(
        currentBuild: currentBuild,
        latestBuild: latestBuild,
        versionName: (json['name'] as String?)?.trim().isNotEmpty == true
            ? json['name'] as String
            : tag,
        downloadUrl: apkUrl,
        notes: (json['body'] as String?) ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}
