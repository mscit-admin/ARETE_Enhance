import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/pill.dart';
import '../../state/connect_controller.dart';

/// Shown to a trainer: their personal QR code that members scan to link up.
class TrainerQrScreen extends StatefulWidget {
  const TrainerQrScreen({super.key});

  @override
  State<TrainerQrScreen> createState() => _TrainerQrScreenState();
}

class _TrainerQrScreenState extends State<TrainerQrScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<ConnectController>().loadTrainerCode());
  }

  @override
  Widget build(BuildContext context) {
    final connect = context.watch<ConnectController>();
    final p = context.palette;
    final code = connect.trainerCode;
    final payload = connect.qrPayload;

    return Scaffold(
      appBar: AppBar(title: const Text('My coach QR')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Pill('Trainer', tone: PillTone.teal),
                const SizedBox(height: AppSpacing.lg),
                Text('Share this code with your clients',
                    textAlign: TextAlign.center,
                    style: context.textStyles.titleLarge),
                const SizedBox(height: 6),
                Text('They scan it in the app to connect with you.',
                    textAlign: TextAlign.center,
                    style:
                        context.textStyles.bodySmall?.copyWith(color: p.muted)),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: payload == null
                      ? const SizedBox(
                          width: 240,
                          height: 240,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : QrImageView(
                          data: payload,
                          size: 240,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.ink,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.ink,
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (code != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: p.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Text('Or share the code above manually.',
                    style:
                        context.textStyles.bodySmall?.copyWith(color: p.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
