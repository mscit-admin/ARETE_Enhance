import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'update_service.dart';

/// Runs a user-initiated "check for updates" (e.g. from the side-menu button).
///
/// It reports progress through snackbars on the *root* messenger rather than a
/// blocking dialog or the browser, so it keeps working after the menu that
/// launched it has closed, and never "flashes" through an external screen. The
/// caller resolves [messenger] and [l] before closing the menu and hands them
/// in, so this function touches no possibly-defunct BuildContext across awaits.
Future<void> runUpdateCheck(
  ScaffoldMessengerState messenger,
  AppLocalizations l,
) async {
  final service = UpdateService();

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 3),
      content: Text(l.updateChecking),
    ),
  );

  final info = await service.check();
  if (info == null) {
    // Either already on the latest build, or the check couldn't reach GitHub.
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(l.updateUpToDate)));
    return;
  }

  // Download the new APK quietly in the background behind a small progress bar.
  final progress = ValueNotifier<double>(0);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(days: 1),
      content: ValueListenableBuilder<double>(
        valueListenable: progress,
        builder: (_, p, __) => Row(
          children: [
            Expanded(child: Text(l.updateDownloading)),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: LinearProgressIndicator(
                value: p > 0 ? p : null,
                backgroundColor: Colors.white24,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  final path =
      await service.download(info, onProgress: (p) => progress.value = p);
  progress.dispose();
  messenger.hideCurrentSnackBar();
  if (path == null) {
    messenger.showSnackBar(SnackBar(content: Text(l.updateFailed)));
    return;
  }

  // Ready — one tap opens the system installer (the only OS prompt).
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 30),
      content: Text(l.updateReady),
      action: SnackBarAction(
        label: l.updateInstall,
        onPressed: () => service.install(path),
      ),
    ),
  );
}
