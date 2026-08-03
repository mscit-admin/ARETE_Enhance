import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// One stop in the guided tour: a widget to spotlight plus the copy shown in
/// the bubble. [before] runs first (e.g. switch tab / role) so the target is
/// on screen when it's measured.
class TourStep {
  const TourStep({
    this.target,
    required this.title,
    required this.body,
    this.circle = false,
    this.before,
  });

  /// The widget to highlight. Null shows a centred message with no cut-out.
  final GlobalKey? target;
  final String title;
  final String body;

  /// Draw the hole as a circle (nav buttons / the round FAB) vs a rounded box.
  final bool circle;

  /// Optional async setup (navigation) to run before measuring the target.
  final Future<void> Function()? before;
}

/// Drives an in-app spotlight walkthrough: dims the screen, cuts a hole around
/// each target, shows an explanatory bubble, and advances on tap / Next.
class GuidedTour {
  GuidedTour(this.context, this.steps, {this.onFinished});

  final BuildContext context;
  final List<TourStep> steps;
  final VoidCallback? onFinished;

  OverlayEntry? _entry;
  int _index = 0;
  Rect? _rect;
  bool _busy = false;

  Future<void> start() async {
    if (steps.isEmpty) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(builder: _build);
    overlay.insert(_entry!);
    await _present();
  }

  Future<void> _nextFrame() {
    final c = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => c.complete());
    WidgetsBinding.instance.scheduleFrame();
    return c.future;
  }

  Future<void> _present() async {
    if (_busy) return;
    _busy = true;
    final step = steps[_index];
    _rect = null;
    _entry?.markNeedsBuild(); // dim immediately while we set up

    if (step.before != null) {
      await step.before!();
    }
    // Let a tab/role switch rebuild and lay out.
    await _nextFrame();
    await _nextFrame();

    final ctx = step.target?.currentContext;
    if (ctx != null && ctx.mounted) {
      // Bring it into view if it lives inside a scroll view.
      try {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 260),
          alignment: 0.25,
        );
      } catch (_) {}
      await _nextFrame();
      final box = ctx.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        final topLeft = box.localToGlobal(Offset.zero);
        _rect = topLeft & box.size;
      }
    }

    _busy = false;
    _entry?.markNeedsBuild();
  }

  void _next() {
    if (_busy) return;
    if (_index >= steps.length - 1) {
      _finish();
      return;
    }
    _index++;
    _present();
  }

  void _finish() {
    _entry?.remove();
    _entry = null;
    onFinished?.call();
  }

  Widget _build(BuildContext ctx) {
    final step = steps[_index];
    return _SpotlightView(
      rect: _rect,
      circle: step.circle,
      title: step.title,
      body: step.body,
      index: _index,
      total: steps.length,
      onNext: _next,
      onSkip: _finish,
    );
  }
}

class _SpotlightView extends StatelessWidget {
  const _SpotlightView({
    required this.rect,
    required this.circle,
    required this.title,
    required this.body,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onSkip,
  });

  final Rect? rect;
  final bool circle;
  final String title;
  final String body;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    RRect? hole;
    if (rect != null) {
      final inflated = rect!.inflate(8);
      final r = circle
          ? Radius.circular(inflated.longestSide / 2)
          : const Radius.circular(18);
      hole = RRect.fromRectAndRadius(inflated, r);
    }

    // Place the bubble opposite the target so it never hides it.
    final below = rect == null || rect!.center.dy < size.height * 0.5;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Scrim + hole. Tapping the dark area advances the tour.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onNext,
              child: CustomPaint(painter: _HolePainter(hole)),
            ),
          ),
          // Explanatory bubble.
          Positioned(
            left: AppSpacing.screen,
            right: AppSpacing.screen,
            top: below
                ? (rect == null
                    ? size.height * 0.5 - 90
                    : rect!.bottom + 18)
                : null,
            bottom: below ? null : size.height - rect!.top + 18,
            child: SafeArea(
              minimum: EdgeInsets.only(
                  top: padding.top > 0 ? 0 : 8, bottom: 8),
              child: _Bubble(
                title: title,
                body: body,
                index: index,
                total: total,
                onNext: onNext,
                onSkip: onSkip,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.title,
    required this.body,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onSkip,
  });

  final String title;
  final String body;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final isLast = index >= total - 1;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${index + 1}/$total',
              style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(title,
              style: context.textStyles.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(body,
              style: context.textStyles.bodyMedium
                  ?.copyWith(color: p.muted, height: 1.4)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              TextButton(
                onPressed: onSkip,
                child: Text(l.helpSkip,
                    style: TextStyle(color: p.muted)),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onNext,
                child: Text(isLast ? l.helpDone : l.helpNext),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HolePainter extends CustomPainter {
  _HolePainter(this.hole);

  final RRect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = const Color(0xCC000000);
    if (hole == null) {
      canvas.drawRect(Offset.zero & size, scrim);
      return;
    }
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(hole!)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, scrim);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.accent;
    canvas.drawRRect(hole!, border);
  }

  @override
  bool shouldRepaint(_HolePainter old) => old.hole != hole;
}
