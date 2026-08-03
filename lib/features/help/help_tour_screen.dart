import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'help_content.dart';

/// Full-screen in-app assistant: a swipeable, role-aware walkthrough of the
/// app. Opens once on first run and can be replayed from the account menu.
class HelpTourScreen extends StatefulWidget {
  const HelpTourScreen({super.key, required this.isTrainer, this.onFinished});

  final bool isTrainer;

  /// Called after the guide is completed or skipped (used to mark it seen).
  final VoidCallback? onFinished;

  /// Push the guide as a full-screen dialog.
  static Future<void> show(
    BuildContext context, {
    required bool isTrainer,
    VoidCallback? onFinished,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            HelpTourScreen(isTrainer: isTrainer, onFinished: onFinished),
      ),
    );
  }

  @override
  State<HelpTourScreen> createState() => _HelpTourScreenState();
}

class _HelpTourScreenState extends State<HelpTourScreen> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() {
    widget.onFinished?.call();
    Navigator.of(context).pop();
  }

  void _next(int total) {
    if (_index >= total - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final steps = helpStepsFor(l, isTrainer: widget.isTrainer);
    final isLast = _index >= steps.length - 1;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip in the top corner.
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(l.helpSkip,
                      style: TextStyle(color: p.muted, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: steps.length,
                itemBuilder: (_, i) => _HelpPage(step: steps[i]),
              ),
            ),
            // Dots.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < steps.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.accent : p.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Controls.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: _index == 0
                        ? const SizedBox.shrink()
                        : TextButton(
                            onPressed: _back,
                            child: Text(l.helpBack,
                                style: TextStyle(color: p.muted)),
                          ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _next(steps.length),
                      child: Text(isLast ? l.helpDone : l.helpNext),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpPage extends StatelessWidget {
  const _HelpPage({required this.step});

  final HelpStep step;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 108,
            height: 108,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: step.tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: step.tint.withValues(alpha: 0.35)),
            ),
            child: Icon(step.icon, size: 52, color: step.tint),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: context.textStyles.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium?.copyWith(
              color: p.muted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
