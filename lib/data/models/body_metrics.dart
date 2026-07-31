/// A point-in-time snapshot of the member's body measurements.
class BodyMetrics {
  const BodyMetrics({
    required this.weightKg,
    required this.heightCm,
    this.bodyFatPercent,
    this.waistCm,
  });

  final double weightKg;
  final double heightCm;
  final double? bodyFatPercent;
  final double? waistCm;

  /// Body Mass Index = weight(kg) / height(m)^2.
  double get bmi {
    final m = heightCm / 100.0;
    if (m <= 0) return 0;
    return weightKg / (m * m);
  }

  String get bmiCategory {
    final b = bmi;
    if (b < 18.5) return 'Underweight';
    if (b < 25) return 'Healthy';
    if (b < 30) return 'Overweight';
    return 'Obese';
  }

  /// Basal Metabolic Rate (Mifflin-St Jeor). Needs age + gender-based constant.
  /// [maleOffset] is +5 for male, -161 for female (caller supplies).
  double bmr({required int ageYears, required double genderOffset}) {
    return (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears) + genderOffset;
  }

  BodyMetrics copyWith({
    double? weightKg,
    double? heightCm,
    double? bodyFatPercent,
    double? waistCm,
  }) {
    return BodyMetrics(
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
      waistCm: waistCm ?? this.waistCm,
    );
  }

  Map<String, dynamic> toJson() => {
        'weightKg': weightKg,
        'heightCm': heightCm,
        'bodyFatPercent': bodyFatPercent,
        'waistCm': waistCm,
      };

  factory BodyMetrics.fromJson(Map<String, dynamic> json) => BodyMetrics(
        weightKg: (json['weightKg'] as num).toDouble(),
        heightCm: (json['heightCm'] as num).toDouble(),
        bodyFatPercent: (json['bodyFatPercent'] as num?)?.toDouble(),
        waistCm: (json['waistCm'] as num?)?.toDouble(),
      );
}
