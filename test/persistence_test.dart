import 'package:arete/data/mock/mock_data.dart';
import 'package:arete/data/models/member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Member serialises and deserialises without loss', () {
    final m = MockData.member;
    final copy = Member.fromJson(m.toJson());

    expect(copy.id, m.id);
    expect(copy.fullName, m.fullName);
    expect(copy.email, m.email);
    expect(copy.goal, m.goal);
    expect(copy.units, m.units);
    expect(copy.metrics.weightKg, m.metrics.weightKg);
    expect(copy.dailyStats.waterGlasses, m.dailyStats.waterGlasses);
    expect(copy.membership.tier, m.membership.tier);
    expect(copy.badges, m.badges);
  });
}
