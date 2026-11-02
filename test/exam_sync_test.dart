import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/exam.dart';
import 'package:focus/core/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> make() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    );
  }

  test('saving an exam works even if the block screen cannot be told', () async {
    final c = await make();
    addTearDown(c.dispose);
    await c
        .read(examProvider.notifier)
        .set(Exam(name: 'NEET', date: DateTime(2027, 5, 3)));
    expect(c.read(examProvider)?.name, 'NEET');
  });

  test('clearing the exam works too', () async {
    final c = await make();
    addTearDown(c.dispose);
    await c
        .read(examProvider.notifier)
        .set(Exam(name: 'NEET', date: DateTime(2027, 5, 3)));
    await c.read(examProvider.notifier).clear();
    expect(c.read(examProvider), isNull);
  });

  test('syncing with no exam does not throw', () async {
    final c = await make();
    addTearDown(c.dispose);
    await c.read(examProvider.notifier).syncToBlockScreen();
    expect(c.read(examProvider), isNull);
  });
}
