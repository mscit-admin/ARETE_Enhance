import 'package:arete/data/models/auth_user.dart';
import 'package:arete/data/repositories/local_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sign up creates a session that persists', () async {
    final repo = LocalAuthRepository();
    final u = await repo.signUp(
        name: 'Yahya', email: 'A@Example.com', password: 'secret1');
    expect(u.email, 'a@example.com'); // normalised
    final current = await repo.currentUser();
    expect(current?.email, 'a@example.com');
    expect(current?.name, 'Yahya');
  });

  test('duplicate email is rejected', () async {
    final repo = LocalAuthRepository();
    await repo.signUp(name: 'A', email: 'a@b.com', password: 'secret1');
    expect(
      () => repo.signUp(name: 'B', email: 'a@b.com', password: 'another1'),
      throwsA(isA<AuthException>()),
    );
  });

  test('wrong password fails, correct password signs in', () async {
    final repo = LocalAuthRepository();
    await repo.signUp(name: 'A', email: 'a@b.com', password: 'secret1');
    await repo.signOut();
    expect(currentSessionEmpty(repo), completion(isTrue));

    expect(
      () => repo.signIn(email: 'a@b.com', password: 'wrongpass'),
      throwsA(isA<AuthException>()),
    );
    final u = await repo.signIn(email: 'a@b.com', password: 'secret1');
    expect(u.name, 'A');
  });
}

Future<bool> currentSessionEmpty(LocalAuthRepository repo) async =>
    (await repo.currentUser()) == null;
