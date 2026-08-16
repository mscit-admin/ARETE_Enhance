/// Pure time-of-day helpers shared by the reminder controllers.
///
/// Kept free of Flutter and plugin imports so the scheduling rules can be
/// unit-tested on their own.
class ReminderMath {
  const ReminderMath._();

  static const int minutesPerDay = 24 * 60;

  /// Never place two reminders closer together than this.
  static const int defaultMinGapMinutes = 30;

  /// Spread [count] reminders across the window `[startMinutes, endMinutes)`.
  ///
  /// The first reminder lands on [startMinutes] and the rest follow at an even
  /// step, so eight glasses between 8:00 and 20:00 become 8:00, 9:30, 11:00 …
  /// 18:30. Slots are rounded to the nearest five minutes for tidy times.
  ///
  /// If the requested count would pack them tighter than [minGapMinutes] — or
  /// past [maxSlots] — the list is shortened rather than crowded.
  static List<int> spread({
    required int startMinutes,
    required int endMinutes,
    required int count,
    int minGapMinutes = defaultMinGapMinutes,
    int maxSlots = 24,
  }) {
    if (count <= 0 || maxSlots <= 0) return const [];
    final start = startMinutes.clamp(0, minutesPerDay - 1);
    final end = endMinutes.clamp(0, minutesPerDay - 1);
    if (end <= start) return [start];

    final window = end - start;
    final fits = window ~/ minGapMinutes;
    if (fits < 1) return [start];

    var n = count;
    if (n > fits) n = fits;
    if (n > maxSlots) n = maxSlots;

    final step = window ~/ n;
    return [for (var i = 0; i < n; i++) roundToFive(start + i * step)];
  }

  /// Round a minute-of-day to the nearest five minutes, staying inside the day.
  static int roundToFive(int minuteOfDay) {
    final rounded = ((minuteOfDay + 2) ~/ 5) * 5;
    return rounded.clamp(0, minutesPerDay - 1);
  }

  static int hourOf(int minuteOfDay) => minuteOfDay ~/ 60;

  static int minuteOf(int minuteOfDay) => minuteOfDay % 60;

  static int toMinuteOfDay(int hour, int minute) => hour * 60 + minute;

  /// Minutes-of-day for "now", used by the in-app prompt ticker.
  static int nowMinuteOfDay([DateTime? now]) {
    final t = now ?? DateTime.now();
    return t.hour * 60 + t.minute;
  }

  /// `08:30` — a locale-independent label for a slot (the UI formats times of
  /// day itself where a 12-hour clock is wanted).
  static String format24(int minuteOfDay) {
    final h = hourOf(minuteOfDay).toString().padLeft(2, '0');
    final m = minuteOf(minuteOfDay).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
