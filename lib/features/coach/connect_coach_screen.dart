import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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

class _ConnectCoachScreenState extends State<ConnectCoachScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  final _codeField = TextEditingController();
  bool _handling = false;
  String? _error;

  @override
  void dispose() {
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
                child: Stack(
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
                          child: Text(
                            l.connectCameraUnavailable,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
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
                          border: Border.all(color: AppColors.brandGreen, width: 3),
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
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
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
