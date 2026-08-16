import '../../core/notifications/reminder_math.dart';

/// The meals a schedule can hold. `preWorkout`/`postWorkout` exist so a coach
/// plan can pin meals around a session later on.
enum MealKind { breakfast, snack, lunch, dinner, preWorkout, postWorkout }

/// Where a slot came from. Everything is member-defined today; coach-issued
/// nutrition plans will arrive as [MealSource.coach] and flow through the same
/// reminder pipeline without changes.
enum MealSource { self, coach }

/// One entry in the member's daily meal schedule.
///
/// This is the contract the Meals screen will edit and the reminder scheduler
/// reads — the two are deliberately decoupled so either can be built first.
class MealSlot {
  const MealSlot({
    required this.id,
    required this.kind,
    required this.minuteOfDay,
    this.name = '',
    this.enabled = true,
    this.source = MealSource.self,
    this.note = '',
  });

  final String id;
  final MealKind kind;

  /// Time of day, in minutes since midnight (13:30 → 810).
  final int minuteOfDay;

  /// Member-supplied name. Empty means "use the localized name of [kind]".
  final String name;
  final bool enabled;
  final MealSource source;

  /// Free-text hint shown with the reminder (e.g. "protein + slow carbs").
  final String note;

  int get hour => ReminderMath.hourOf(minuteOfDay);
  int get minute => ReminderMath.minuteOf(minuteOfDay);

  /// The default fixed schedule: three meals and two snacks.
  ///
  /// A fresh growable list every call — callers sort and edit it in place.
  static List<MealSlot> defaults() => [
        const MealSlot(
            id: 'breakfast', kind: MealKind.breakfast, minuteOfDay: 7 * 60 + 30),
        const MealSlot(
            id: 'snack_am', kind: MealKind.snack, minuteOfDay: 10 * 60 + 30),
        const MealSlot(
            id: 'lunch', kind: MealKind.lunch, minuteOfDay: 13 * 60 + 30),
        const MealSlot(
            id: 'snack_pm', kind: MealKind.snack, minuteOfDay: 16 * 60 + 30),
        const MealSlot(id: 'dinner', kind: MealKind.dinner, minuteOfDay: 20 * 60),
      ];

  MealSlot copyWith({
    MealKind? kind,
    int? minuteOfDay,
    String? name,
    bool? enabled,
    MealSource? source,
    String? note,
  }) =>
      MealSlot(
        id: id,
        kind: kind ?? this.kind,
        minuteOfDay: minuteOfDay ?? this.minuteOfDay,
        name: name ?? this.name,
        enabled: enabled ?? this.enabled,
        source: source ?? this.source,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'minuteOfDay': minuteOfDay,
        'name': name,
        'enabled': enabled,
        'source': source.name,
        'note': note,
      };

  /// Tolerant of older/partial payloads — an unknown kind falls back to a snack
  /// so a schedule written by a future version still loads.
  factory MealSlot.fromJson(Map<String, dynamic> j) => MealSlot(
        id: (j['id'] ?? '').toString(),
        kind: MealKind.values.firstWhere(
          (k) => k.name == j['kind'],
          orElse: () => MealKind.snack,
        ),
        minuteOfDay:
            ((j['minuteOfDay'] as num?)?.toInt() ?? 0).clamp(0, ReminderMath.minutesPerDay - 1),
        name: (j['name'] ?? '').toString(),
        enabled: j['enabled'] as bool? ?? true,
        source: MealSource.values.firstWhere(
          (s) => s.name == j['source'],
          orElse: () => MealSource.self,
        ),
        note: (j['note'] ?? '').toString(),
      );
}
