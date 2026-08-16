import '../../data/models/meal_slot.dart';

/// Text for OS-level notifications.
///
/// These fire while ARETE is closed, so `AppLocalizations` — which needs a live
/// `BuildContext` — is out of reach. The handful of strings the scheduler needs
/// therefore live here in the three languages the app ships, and
/// [localeCode] mirrors whatever language the member picked.
class NotificationCopy {
  const NotificationCopy._();

  static const List<String> supported = ['en', 'ar', 'fr'];

  static String _locale = 'en';

  static String get localeCode => _locale;

  /// Mirror the app's language. A null/unknown code falls back to English.
  static void setLocale(String? code) {
    _locale = supported.contains(code) ? code! : 'en';
  }

  static String _pick(Map<String, String> byLocale) =>
      byLocale[_locale] ?? byLocale['en']!;

  // ---- Water ----

  static String get waterTitle => _pick(const {
        'en': 'Time to hydrate 💧',
        'ar': 'وقت شرب الماء 💧',
        'fr': "C'est l'heure de s'hydrater 💧",
      });

  /// [glass] is 1-based: "Glass 3 of 8".
  static String waterBody(int glass, int total) => _pick({
        'en': 'Glass $glass of $total — drink it and log it in ARETE.',
        'ar': 'الكوب $glass من $total — اشربه وسجّله في ARETE.',
        'fr': 'Verre $glass sur $total — buvez-le et notez-le dans ARETE.',
      });

  static String get waterBodyPlain => _pick(const {
        'en': 'Drink a glass of water and log it in ARETE.',
        'ar': 'اشرب كوب ماء وسجّله في ARETE.',
        'fr': "Buvez un verre d'eau et notez-le dans ARETE.",
      });

  // ---- Meals ----

  static String mealTitle(String mealName) => _pick({
        'en': '$mealName time 🍽️',
        'ar': 'موعد $mealName 🍽️',
        'fr': "C'est l'heure du repas : $mealName 🍽️",
      });

  static String get mealBody => _pick(const {
        'en': 'Stick to your plan — eat on time.',
        'ar': 'التزم بجدولك — تناول وجبتك في وقتها.',
        'fr': 'Suivez votre plan — mangez à l’heure.',
      });

  /// The localized name of a meal kind, used when the member has not renamed
  /// the slot.
  static String mealKind(MealKind kind) => _pick(switch (kind) {
        MealKind.breakfast => const {
            'en': 'Breakfast',
            'ar': 'الفطور',
            'fr': 'Petit-déjeuner',
          },
        MealKind.snack => const {
            'en': 'Snack',
            'ar': 'وجبة خفيفة',
            'fr': 'Collation',
          },
        MealKind.lunch => const {
            'en': 'Lunch',
            'ar': 'الغداء',
            'fr': 'Déjeuner',
          },
        MealKind.dinner => const {
            'en': 'Dinner',
            'ar': 'العشاء',
            'fr': 'Dîner',
          },
        MealKind.preWorkout => const {
            'en': 'Pre-workout meal',
            'ar': 'وجبة ما قبل التمرين',
            'fr': 'Repas avant l’entraînement',
          },
        MealKind.postWorkout => const {
            'en': 'Post-workout meal',
            'ar': 'وجبة ما بعد التمرين',
            'fr': 'Repas après l’entraînement',
          },
      });

  /// Slot name for display: the custom name when set, else the kind's name.
  static String mealName(MealSlot slot) =>
      slot.name.trim().isNotEmpty ? slot.name.trim() : mealKind(slot.kind);

  // ---- Tips ----

  static String get tipTitle => _pick(const {
        'en': 'Tip of the day 💡',
        'ar': 'نصيحة اليوم 💡',
        'fr': 'Conseil du jour 💡',
      });
}
