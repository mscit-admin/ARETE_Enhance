/// Whether a component of a meal is eaten or drunk. Drinks are part of the
/// meal — the daily water goal is tracked separately, on top of these.
enum MealItemKind { food, drink }

/// One component of a meal: "Grilled chicken · 150 g", "Green tea · 1 cup".
///
/// [amount] is free text on purpose — members and coaches describe portions in
/// whatever way suits them (grams, cups, pieces), and nothing in the app does
/// arithmetic on it.
class MealItem {
  const MealItem({
    required this.name,
    this.amount = '',
    this.kind = MealItemKind.food,
  });

  final String name;
  final String amount;
  final MealItemKind kind;

  bool get isDrink => kind == MealItemKind.drink;

  /// "Grilled chicken · 150 g" — or just the name when no amount was given.
  String get label =>
      amount.trim().isEmpty ? name.trim() : '${name.trim()} · ${amount.trim()}';

  MealItem copyWith({String? name, String? amount, MealItemKind? kind}) =>
      MealItem(
        name: name ?? this.name,
        amount: amount ?? this.amount,
        kind: kind ?? this.kind,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'kind': kind.name,
      };

  factory MealItem.fromJson(Map<String, dynamic> j) => MealItem(
        name: (j['name'] ?? '').toString(),
        amount: (j['amount'] ?? '').toString(),
        kind: MealItemKind.values.firstWhere(
          (k) => k.name == j['kind'],
          orElse: () => MealItemKind.food,
        ),
      );

  /// Parse a stored list, dropping anything unnamed.
  static List<MealItem> listFromJson(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is Map) MealItem.fromJson(e.cast<String, dynamic>()),
    ].where((i) => i.name.trim().isNotEmpty).toList();
  }
}
