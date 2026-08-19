import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/member.dart';
import '../../../shared/widgets/gradient_avatar.dart';

/// The member's avatar. When a profile photo is set it renders the photo with a
/// lime glow ring and a small membership-tier badge in the top corner; with no
/// photo it falls back to the initials gradient tile.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.member, this.size = 50});

  final Member member;
  final double size;

  bool get _hasPhoto =>
      member.photoUrl != null && member.photoUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasPhoto) {
      return GradientAvatar(
        initials: initialsFrom(member.fullName),
        size: size,
        tone: AvatarTone.lime,
      );
    }

    final radius = size * 0.3;
    final badge = size * 0.42;

    return SizedBox(
      // Room for the badge/glow to sit slightly outside the photo.
      width: size + badge * 0.5,
      height: size + badge * 0.5,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Glowing photo tile.
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: AppColors.accent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.55),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
              image: DecorationImage(
                image: NetworkImage(member.photoUrl!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Membership-tier badge, top corner (RTL-aware).
          PositionedDirectional(
            top: -badge * 0.28,
            end: -badge * 0.28,
            child: _TierBadge(tier: member.membership.tier, size: badge),
          ),
        ],
      ),
    );
  }
}

/// Small circular badge coloured by membership tier.
class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier, required this.size});

  final MembershipTier tier;
  final double size;

  Color get _color => switch (tier) {
        MembershipTier.basic => AppColors.slate,
        MembershipTier.silver => const Color(0xFF9AA7B4),
        MembershipTier.gold => AppColors.gold,
        MembershipTier.elite => AppColors.accent,
      };

  @override
  Widget build(BuildContext context) {
    final fg = tier == MembershipTier.elite ? AppColors.onAccent : Colors.white;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      child: Icon(Icons.workspace_premium, size: size * 0.6, color: fg),
    );
  }
}
