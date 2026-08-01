import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/trainer.dart';
import '../../data/models/trainer_plan.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/gradient_avatar.dart';
import '../../shared/widgets/pill.dart';
import '../../state/connect_controller.dart';
import '../../state/messaging_controller.dart';
import '../../state/my_plan_controller.dart';
import '../../state/profile_controller.dart';
import '../trainer/plan_detail_screen.dart';
import 'connect_coach_screen.dart';
import 'widgets/thread_bubble.dart';

/// Trainee-side Coach tab: shows the linked coach, the plan they assigned, and
/// a real conversation with them. When no coach is linked yet it invites the
/// member to scan their coach's QR code.
class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _input = TextEditingController();
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    // Keep the plan and conversation live while the tab is open.
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _refresh() {
    context.read<MyPlanController>().load();
    final coach = context.read<ProfileController>().assignedTrainer;
    if (coach != null) {
      context.read<MessagingController>().load(coach.id);
    }
  }

  Future<void> _connectCoach() async {
    final l = AppLocalizations.of(context);
    final linked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ConnectCoachScreen()),
    );
    if (linked != true || !mounted) return;
    await context.read<ProfileController>().load();
    await context.read<ConnectController>().loadCoach();
    if (!mounted) return;
    _refresh();
    // Surface the coach's name on success.
    final coach = context.read<ProfileController>().assignedTrainer;
    final name = coach?.fullName.split(' ').first ??
        (context.read<ConnectController>().coach?['full_name'] as String?)
            ?.split(' ')
            .first ??
        '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.linkConnectedNamed(name))),
    );
  }

  Future<void> _send() async {
    final coach = context.read<ProfileController>().assignedTrainer;
    if (coach == null) return;
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    await context.read<MessagingController>().send(coach.id, text);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final coach = context.watch<ProfileController>().assignedTrainer;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navCoach),
        actions: [
          IconButton(
            tooltip: l.coachConnectTooltip,
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _connectCoach,
          ),
        ],
      ),
      body: SafeArea(
        child: coach == null
            ? _NoCoach(l: l, onConnect: _connectCoach)
            : _Conversation(
                coach: coach,
                input: _input,
                onSend: _send,
              ),
      ),
    );
  }
}

class _NoCoach extends StatelessWidget {
  const _NoCoach({required this.l, required this.onConnect});
  final AppLocalizations l;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, size: 44, color: p.muted),
            const SizedBox(height: AppSpacing.md),
            Text(l.coachNoCoach, style: context.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(l.coachConnectPrompt,
                textAlign: TextAlign.center,
                style: context.textStyles.bodySmall?.copyWith(color: p.muted)),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: onConnect,
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: Text(l.coachConnectBtn),
            ),
          ],
        ),
      ),
    );
  }
}

class _Conversation extends StatelessWidget {
  const _Conversation(
      {required this.coach, required this.input, required this.onSend});
  final Trainer coach;
  final TextEditingController input;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final plan = context.watch<MyPlanController>().current;
    final messages = context.watch<MessagingController>().thread(coach.id);

    return Column(
      children: [
        // ---- Coach header ----
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Row(
            children: [
              GradientAvatar(
                initials: initialsFrom(coach.fullName),
                size: 48,
                tone: AvatarTone.ember,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.trainerCoachName(coach.fullName.split(' ').first),
                        style: context.textStyles.titleLarge),
                    Text(
                      coach.specialty.isEmpty
                          ? l.coachCertified
                          : coach.specialty,
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: p.muted),
                    ),
                  ],
                ),
              ),
              Pill(l.coachOnline, tone: PillTone.teal, icon: Icons.circle),
            ],
          ),
        ),
        // ---- Assigned plan card ----
        if (plan != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.sm),
            child: AppCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: plan)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: p.emberSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assignment, color: AppColors.ember),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.coachYourPlan,
                            style: context.textStyles.bodySmall
                                ?.copyWith(color: p.muted)),
                        Text(plan.name, style: context.textStyles.titleMedium),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: p.muted),
                ],
              ),
            ),
          ),
        Divider(height: 1, color: p.line),
        // ---- Conversation ----
        Expanded(
          child: ListView(
            reverse: true,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen, vertical: AppSpacing.md),
            children: [
              for (final m in messages.reversed)
                ThreadBubble(
                  message: m,
                  mine: !m.fromCoach,
                  onViewPlan: m.isPlanCard && plan != null
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => PlanDetailScreen(plan: plan)),
                          )
                      : null,
                ),
            ],
          ),
        ),
        _Composer(controller: input, hint: l.coachMessageHint, onSend: onSend),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer(
      {required this.controller, required this.hint, required this.onSend});
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 4,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(hintText: hint, isDense: true),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Material(
            color: AppColors.ember,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSend,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.arrow_upward, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
