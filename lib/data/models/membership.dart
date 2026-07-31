import '../../core/constants/enums.dart';

/// The member's gym membership state.
class Membership {
  const Membership({
    required this.tier,
    required this.status,
    required this.joinedOn,
    required this.renewsOn,
  });

  final MembershipTier tier;
  final MembershipStatus status;
  final DateTime joinedOn;
  final DateTime renewsOn;

  int get daysUntilRenewal => renewsOn.difference(DateTime.now()).inDays;

  Membership copyWith({
    MembershipTier? tier,
    MembershipStatus? status,
    DateTime? joinedOn,
    DateTime? renewsOn,
  }) {
    return Membership(
      tier: tier ?? this.tier,
      status: status ?? this.status,
      joinedOn: joinedOn ?? this.joinedOn,
      renewsOn: renewsOn ?? this.renewsOn,
    );
  }

  Map<String, dynamic> toJson() => {
        'tier': tier.name,
        'status': status.name,
        'joinedOn': joinedOn.toIso8601String(),
        'renewsOn': renewsOn.toIso8601String(),
      };

  factory Membership.fromJson(Map<String, dynamic> json) => Membership(
        tier: MembershipTier.values.byName(json['tier'] as String),
        status: MembershipStatus.values.byName(json['status'] as String),
        joinedOn: DateTime.parse(json['joinedOn'] as String),
        renewsOn: DateTime.parse(json['renewsOn'] as String),
      );
}
