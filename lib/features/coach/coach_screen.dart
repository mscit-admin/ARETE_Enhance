import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/coach_chat.dart';
import '../../data/models/trainer.dart';
import '../../shared/widgets/gradient_avatar.dart';
import '../../shared/widgets/pill.dart';
import '../../state/coach_controller.dart';
import '../../state/profile_controller.dart';
import 'widgets/chat_bubble.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = context.read<CoachController>();
      if (c.status == LoadStatus.idle) c.load();
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    context.read<CoachController>().sendMessage(text);
    _input.clear();
  }

  Future<void> _openBooking(Trainer? trainer) async {
    final now = DateTime.now();
    final slots = [
      for (var d = 1; d <= 4; d++)
        DateTime(now.year, now.month, now.day + d, 18, 0),
    ];
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (_) => _BookingSheet(slots: slots),
    );
    if (picked != null && mounted) {
      context
          .read<CoachController>()
          .bookSession(picked, 'Form check · 1-on-1');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Session booked for ${DateFormat('EEE, MMM d · h:mm a').format(picked)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final coach = context.watch<CoachController>();
    final trainer = context.watch<ProfileController>().assignedTrainer;
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Coach')),
      body: SafeArea(
        child: Column(
          children: [
            _CoachHeader(trainer: trainer),
            if (coach.sessions.isNotEmpty)
              _UpcomingSession(session: coach.sessions.last),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0,
                  AppSpacing.screen, AppSpacing.sm),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openBooking(trainer),
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: const Text('Book a 1-on-1 session'),
                ),
              ),
            ),
            Divider(height: 1, color: p.line),
            Expanded(
              child: coach.status == LoadStatus.ready
                  ? _Thread(
                      messages: coach.messages, typing: coach.coachTyping)
                  : const Center(child: CircularProgressIndicator()),
            ),
            _Composer(controller: _input, onSend: _send),
          ],
        ),
      ),
    );
  }
}

class _CoachHeader extends StatelessWidget {
  const _CoachHeader({required this.trainer});
  final Trainer? trainer;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = trainer; // local promotes; a public field cannot
    final name = t?.fullName ?? 'Your coach';
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Row(
        children: [
          GradientAvatar(
            initials: initialsFrom(name),
            size: 48,
            tone: AvatarTone.ember,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coach ${name.split(' ').first}',
                    style: context.textStyles.titleLarge),
                Text(
                  t == null
                      ? 'Certified personal trainer'
                      : '${t.certifications.join(' · ')} · replies in ~${t.avgResponseHours}h',
                  style:
                      context.textStyles.bodySmall?.copyWith(color: p.muted),
                ),
              ],
            ),
          ),
          const Pill('Online', tone: PillTone.teal, icon: Icons.circle),
        ],
      ),
    );
  }
}

class _UpcomingSession extends StatelessWidget {
  const _UpcomingSession({required this.session});
  final CoachSession session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.palette.tealSoft,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_available, color: AppColors.teal),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d · h:mm a').format(session.start),
                    style: context.textStyles.titleMedium,
                  ),
                  Text('${session.focus} · ${session.minutes} min',
                      style: context.textStyles.bodySmall),
                ],
              ),
            ),
            const Pill('Booked', tone: PillTone.teal),
          ],
        ),
      ),
    );
  }
}

class _Thread extends StatelessWidget {
  const _Thread({required this.messages, required this.typing});
  final List<ChatMessage> messages;
  final bool typing;

  @override
  Widget build(BuildContext context) {
    // reverse:true keeps the latest message pinned to the bottom.
    final items = <Widget>[
      if (typing) const _TypingIndicator(),
      for (final m in messages.reversed) ChatBubble(message: m),
    ];
    return ListView(
      reverse: true,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen, vertical: AppSpacing.md),
      children: items,
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.line),
        ),
        child: Text('Coach is typing…',
            style: context.textStyles.bodySmall?.copyWith(color: p.muted)),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
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
              decoration: const InputDecoration(
                hintText: 'Message your coach…',
                isDense: true,
              ),
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

class _BookingSheet extends StatelessWidget {
  const _BookingSheet({required this.slots});
  final List<DateTime> slots;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0,
            AppSpacing.screen, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pick a session time',
                style: context.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            for (final s in slots)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(DateFormat('EEEE, MMM d').format(s)),
                subtitle: Text('${DateFormat('h:mm a').format(s)} · 45 min'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pop(s),
              ),
          ],
        ),
      ),
    );
  }
}
