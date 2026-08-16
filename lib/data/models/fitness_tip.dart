/// The buckets a tip can belong to. The member can mute a whole category from
/// the Alerts screen.
enum TipCategory { training, recovery, nutrition, hydration, mindset }

/// A short piece of coaching advice, carried in the three languages the app
/// ships. Tips are static content — they never hit the network — so a tip can
/// be raised as a notification while ARETE is closed.
class FitnessTip {
  const FitnessTip({
    required this.id,
    required this.category,
    required this.text,
  });

  final String id;
  final TipCategory category;

  /// Locale code → tip text.
  final Map<String, String> text;

  String localized(String localeCode) => text[localeCode] ?? text['en'] ?? '';
}
