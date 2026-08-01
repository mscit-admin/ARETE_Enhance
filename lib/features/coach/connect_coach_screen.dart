import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/connect_controller.dart';

/// Member-facing: scan a trainer's QR code (or type it) to link up.
class ConnectCoachScreen extends StatefulWidget {
  const ConnectCoachScreen({super.key});

  @override
  State<ConnectCoachScreen> createState() => _ConnectCoachScreenState();
}

class _ConnectCoachScreenState extends State<ConnectCoachScreen>
    with WidgetsBindingObserver {
  // Default controller (autoStart = true): the MobileScanner widget starts the
  // camera when it mounts. We only mount it *after* the permission is granted,
  // so the start happens at the right time.
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  final _codeField = TextEditingController();
  bool _handling = false;
  String? _error;
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  bool _checkingPermission = true;

  bool get _cameraGranted => _cameraStatus.isGranted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermission(request: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check after the user comes back from the system settings screen —
    // if they granted the permission there, start the camera automatically.
    if (state == AppLifecycleState.resumed && !_cameraGranted) {
      _refreshPermission(request: false);
    }
  }

  /// Read the permission (optionally requesting it) and start the camera when
  /// it is granted.
  Future<void> _refreshPermission({required bool request}) async {
    var status = await Permission.camera.status;
    if (!status.isGranted && request) {
      status = await Permission.camera.request();
    }
    if (!mounted) return;
    setState(() {
      _cameraStatus = status;
      _checkingPermission = false;
    });
  }

  /// Button action: request the permission; if that doesn't grant it (denied
  /// or permanently denied), open the system settings so it can be granted
  /// there — that path always works even when the in-app dialog won't show.
  Future<void> _enableCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() => _cameraStatus = status);
    if (!status.isGranted) await openAppSettings();
  }

  /// Retry starting the camera (used by the error state's Retry button).
  Future<void> _restart() async {
    try {
      await _controller.start();
    } catch (_) {
      // Ignore — the errorBuilder will surface any persistent failure.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _codeField.dispose();
    super.dispose();
  }

  Future<void> _submit(String raw) async {
    if (_handling) return;
    final code = raw.trim();
    if (code.isEmpty) return;
    setState(() {
      _handling = true;
      _error = null;
    });
    final err = await context.read<ConnectController>().link(code);
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _handling = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.connectTitle)),
      body: SafeArea(
        child: Column(
          children: [
            // ---- Scanner ----
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.screen),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: p.line),
                  color: Colors.black,
                ),
                child: _checkingPermission
                    ? const Center(child: CircularProgressIndicator())
                    : !_cameraGranted
                        ? _CameraPrompt(
                            l: l,
                            status: _cameraStatus,
                            onEnable: _enableCamera)
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              MobileScanner(
                                controller: _controller,
                                onDetect: (capture) {
                                  final raw = capture.barcodes.isNotEmpty
                                      ? capture.barcodes.first.rawValue
                                      : null;
                                  if (raw != null) _submit(raw);
                                },
                                errorBuilder: (context, error, child) => Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.xl),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          l.connectCameraUnavailable,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: Colors.white70),
                                        ),
                                        const SizedBox(height: 6),
                                        // Real error code/message for diagnosis.
                                        Text(
                                          '${error.errorCode.name}'
                                          '${error.errorDetails?.message != null ? ' · ${error.errorDetails!.message}' : ''}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 11),
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        ElevatedButton.icon(
                                          onPressed: _restart,
                                          icon: const Icon(Icons.refresh,
                                              size: 18),
                                          label: Text(l.actionRetry),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // viewfinder frame
                              Center(
                                child: Container(
                                  width: 210,
                                  height: 210,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: AppColors.brandGreen, width: 3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 12,
                                child: Text(
                                  l.connectPointAtQr,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
              ),
            ),
            // ---- Manual entry ----
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0,
                  AppSpacing.screen, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.connectOrEnterCode,
                      style: context.textStyles.labelSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeField,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: l.connectCodeHint,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ElevatedButton(
                        onPressed: _handling
                            ? null
                            : () => _submit(_codeField.text),
                        child: _handling
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(l.connectLink),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(_error!,
                        style: TextStyle(
                            color: AppColors.danger, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown inside the scanner frame when the camera permission isn't granted.
class _CameraPrompt extends StatelessWidget {
  const _CameraPrompt(
      {required this.l, required this.status, required this.onEnable});
  final AppLocalizations l;
  final PermissionStatus status;
  final Future<void> Function() onEnable;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined,
                color: Colors.white70, size: 40),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.connectCameraPermission,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: onEnable,
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: Text(l.connectEnableCamera),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Small diagnostic line (permission state) — helps pinpoint issues.
            Text(
              'camera: ${status.name}',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
