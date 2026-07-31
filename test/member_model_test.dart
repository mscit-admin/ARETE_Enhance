import 'package:arete/core/constants/enums.dart';
import 'package:arete/data/models/body_metrics.dart';
import 'package:arete/data/mock/mock_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BodyMetrics', () {
    test('BMI is computed from weight and height', () {
      const m = BodyMetrics(weightKg: 81, heightCm: 180);
      // 81 / (1.8^2) = 25.0
      expect(m.bmi, closeTo(25.0, 0.01));
      expect(m.bmiCategory, 'Overweight');
    });

    test('healthy BMI is categorised correctly', () {
      const m = BodyMetrics(weightKg: 70, heightCm: 180);
      expect(m.bmiCategory, 'Healthy');
    });

    test('BMR uses the Mifflin-St Jeor equation', () {
      const m = BodyMetrics(weightKg: 80, heightCm: 180);
      // 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5 = 1780
      final bmr = m.bmr(ageYears: 30, genderOffset: 5);
      expect(bmr, closeTo(1780, 0.01));
    });
  });

  group('Member', () {
    test('weekly progress is sessions / target', () {
      final member = MockData.member;
      expect(member.weeklyProgress, closeTo(3 / 4, 0.001));
    });

    test('imperial display weight converts from kg', () {
      final metric = MockData.member;
      final imperial = metric.copyWith(units: UnitSystem.imperial);
      expect(imperial.displayWeight, closeTo(metric.metrics.weightKg * 2.2046, 0.1));
    });

    test('age is derived from date of birth', () {
      final member = MockData.member.copyWith(
        dateOfBirth: DateTime(2000, 1, 1),
      );
      expect(member.ageYears, greaterThanOrEqualTo(25));
    });
  });
}
