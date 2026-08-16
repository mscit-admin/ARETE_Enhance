import 'package:arete/core/notifications/notification_copy.dart';
import 'package:arete/core/notifications/reminder_math.dart';
import 'package:arete/data/models/fitness_tip.dart';
import 'package:arete/data/models/meal_slot.dart';
import 'package:arete/data/tips/fitness_tips.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReminderMath.spread', () {
    test('spreads the daily water target across the active window', () {
      // 8 glasses between 08:00 and 20:00 → one every 90 minutes.
      final slots = ReminderMath.spread(
        startMinutes: 8 * 60,
        endMinutes: 20 * 60,
        count: 8,
      );
      expect(slots.length, 8);
      expect(slots.first, 8 * 60);
      expect(slots[1] - slots[0], 90);
      expect(slots.last, 18 * 60 + 30);
    });

    test('never packs reminders closer than the minimum gap', () {
      final slots = ReminderMath.spread(
        startMinutes: 8 * 60,
        endMinutes: 12 * 60, // a 4-hour window
        count: 20,
        minGapMinutes: 30,
      );
      expect(slots.length, 8); // 240 / 30
      for (var i = 1; i < slots.length; i++) {
        expect(slots[i] - slots[i - 1], greaterThanOrEqualTo(30));
      }
    });

    test('respects the channel capacity', () {
      final slots = ReminderMath.spread(
        startMinutes: 6 * 60,
        endMinutes: 22 * 60,
        count: 40,
        maxSlots: 24,
      );
      expect(slots.length, lessThanOrEqualTo(24));
    });

    test('degenerate windows and counts stay safe', () {
      expect(ReminderMath.spread(startMinutes: 480, endMinutes: 480, count: 5),
          [480]);
      expect(ReminderMath.spread(startMinutes: 480, endMinutes: 300, count: 5),
          [480]);
      expect(ReminderMath.spread(startMinutes: 480, endMinutes: 1200, count: 0),
          isEmpty);
      expect(
          ReminderMath.spread(startMinutes: 480, endMinutes: 1200, count: 1),
          [480]);
    });

    test('formats and splits minutes of day', () {
      expect(ReminderMath.format24(8 * 60 + 5), '08:05');
      expect(ReminderMath.hourOf(810), 13);
      expect(ReminderMath.minuteOf(810), 30);
      expect(ReminderMath.toMinuteOfDay(13, 30), 810);
    });
  });

  group('MealSlot', () {
    test('the default schedule is editable and ordered by time', () {
      final slots = MealSlot.defaults();
      expect(slots.length, 5);
      // Must be growable/mutable — the controller sorts and edits in place.
      slots.sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
      slots.add(const MealSlot(
          id: 'extra', kind: MealKind.snack, minuteOfDay: 22 * 60));
      expect(slots.length, 6);
      expect(slots.first.kind, MealKind.breakfast);
    });

    test('survives a JSON round trip', () {
      const slot = MealSlot(
        id: 'lunch',
        kind: MealKind.lunch,
        minuteOfDay: 13 * 60 + 30,
        name: 'غداء العمل',
        note: 'protein + rice',
        source: MealSource.coach,
        enabled: false,
      );
      final back = MealSlot.fromJson(slot.toJson());
      expect(back.id, slot.id);
      expect(back.kind, MealKind.lunch);
      expect(back.minuteOfDay, 810);
      expect(back.hour, 13);
      expect(back.minute, 30);
      expect(back.name, 'غداء العمل');
      expect(back.note, 'protein + rice');
      expect(back.source, MealSource.coach);
      expect(back.enabled, isFalse);
    });

    test('an unknown kind or source falls back instead of throwing', () {
      final slot = MealSlot.fromJson({
        'id': 'x',
        'kind': 'brunch',
        'source': 'gym',
        'minuteOfDay': 99999,
      });
      expect(slot.kind, MealKind.snack);
      expect(slot.source, MealSource.self);
      expect(slot.minuteOfDay, lessThan(ReminderMath.minutesPerDay));
    });
  });

  group('FitnessTips', () {
    test('every tip carries all three languages', () {
      for (final tip in FitnessTips.all) {
        for (final code in NotificationCopy.supported) {
          expect(tip.text[code], isNotNull, reason: '${tip.id} is missing $code');
          expect(tip.text[code], isNotEmpty, reason: '${tip.id} is empty in $code');
        }
      }
    });

    test('tip ids are unique', () {
      final ids = FitnessTips.all.map((t) => t.id).toSet();
      expect(ids.length, FitnessTips.all.length);
    });

    test('the same day always yields the same tip, and days differ', () {
      final day = DateTime(2026, 3, 14);
      expect(FitnessTips.tipForDay(day).id, FitnessTips.tipForDay(day).id);
      final week = {
        for (var i = 0; i < 7; i++)
          FitnessTips.tipForDay(DateTime(2026, 3, 14 + i)).id,
      };
      expect(week.length, 7); // no repeats inside a week
    });

    test('muted categories are excluded from the rotation', () {
      final only = {TipCategory.hydration};
      for (var i = 0; i < 20; i++) {
        final tip = FitnessTips.tipForDay(DateTime(2026, 1, 1 + i), categories: only);
        expect(tip.category, TipCategory.hydration);
      }
    });

    test('an empty category set still returns a tip', () {
      expect(FitnessTips.forCategories({}), isNotEmpty);
      final tip = FitnessTips.tipForDay(DateTime(2026, 1, 1), categories: {});
      expect(tip.id, isNotEmpty);
    });
  });

  group('NotificationCopy', () {
    tearDown(() => NotificationCopy.setLocale('en'));

    test('follows the app language and falls back to English', () {
      NotificationCopy.setLocale('ar');
      expect(NotificationCopy.localeCode, 'ar');
      expect(NotificationCopy.mealKind(MealKind.breakfast), 'الفطور');

      NotificationCopy.setLocale('de'); // unsupported
      expect(NotificationCopy.localeCode, 'en');
      expect(NotificationCopy.mealKind(MealKind.breakfast), 'Breakfast');
    });

    test('a renamed slot keeps its custom name', () {
      NotificationCopy.setLocale('en');
      const renamed = MealSlot(
          id: 'a', kind: MealKind.snack, minuteOfDay: 600, name: 'Pre-gym shake');
      expect(NotificationCopy.mealName(renamed), 'Pre-gym shake');
      const plain =
          MealSlot(id: 'b', kind: MealKind.dinner, minuteOfDay: 1200);
      expect(NotificationCopy.mealName(plain), 'Dinner');
    });

    test('the water body counts the glass out of the target', () {
      NotificationCopy.setLocale('en');
      expect(NotificationCopy.waterBody(3, 8), contains('3'));
      expect(NotificationCopy.waterBody(3, 8), contains('8'));
    });
  });
}
