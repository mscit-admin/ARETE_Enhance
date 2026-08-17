import '../../core/notifications/reminder_math.dart';
import 'meal_item.dart';

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
    this.items = const [],
    this.days = const {},
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

  /// What the meal is made of — food and drinks alike.
  final List<MealItem> items;

  /// The weekdays this meal applies to, using Dart's convention
  /// (`DateTime.monday` = 1 … `DateTime.sunday` = 7).
  ///
  /// An empty set means *every* day — which is also what a schedule written
  /// before weekly plans existed loads as, so nothing has to be migrated.
  final Set<int> days;

  bool get everyDay => days.isEmpty || days.length >= 7;

  bool appliesOn(int weekday) => days.isEmpty || days.contains(weekday);

  bool appliesToday([DateTime? now]) =>
      appliesOn((now ?? DateTime.now()).weekday);

  List<MealItem> get foods => [for (final i in items) if (!i.isDrink) i];
  List<MealItem> get drinks => [for (final i in items) if (i.isDrink) i];

  /// "Chicken · 150 g, Rice, Water" — the one-line summary used in lists and
  /// in the reminder body when the member wrote no note.
  String get itemsSummary =>
      [for (final i in items) i.label].where((s) => s.isNotEmpty).join('، ');

  /// Monday-first list of weekdays, for pickers that want a stable order.
  static const List<int> allWeekdays = [1, 2, 3, 4, 5, 6, 7];

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
    List<MealItem>? items,
    Set<int>? days,
  }) =>
      MealSlot(
        id: id,
        kind: kind ?? this.kind,
        minuteOfDay: minuteOfDay ?? this.minuteOfDay,
        name: name ?? this.name,
        enabled: enabled ?? this.enabled,
        source: source ?? this.source,
        note: note ?? this.note,
        items: items ?? this.items,
        days: days ?? this.days,
      );

  /// The same meal under a new id — used when a day's meals are copied onto
  /// other days and each copy needs its own identity for the day's tick-list.
  MealSlot withId(String newId) => MealSlot(
        id: newId,
        kind: kind,
        minuteOfDay: minuteOfDay,
        name: name,
        enabled: enabled,
        source: source,
        note: note,
        items: items,
        days: days,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'minuteOfDay': minuteOfDay,
        'name': name,
        'enabled': enabled,
        'source': source.name,
        'note': note,
        'items': [for (final i in items) i.toJson()],
        'days': days.toList()..sort(),
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
        items: MealItem.listFromJson(j['items']),
        days: _weekdaysFromJson(j['days']),
      );

  /// Keeps only real weekdays (1..7); anything else is dropped, which reads as
  /// "every day".
  static Set<int> _weekdaysFromJson(Object? raw) {
    if (raw is! List) return const {};
    final days = <int>{};
    for (final entry in raw) {
      final day =
          entry is num ? entry.toInt() : int.tryParse(entry.toString()) ?? 0;
      if (day >= DateTime.monday && day <= DateTime.sunday) days.add(day);
    }
    return days;
  }
}
