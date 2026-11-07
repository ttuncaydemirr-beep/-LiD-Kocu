import 'package:flutter_test/flutter_test.dart';
import 'package:lid_kocu/services/save_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('boş başlangıç değerleri', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SaveStore s = await SaveStore.open();
    expect(s.lang, isNull);
    expect(s.stateId, isNull);
    expect(s.theme, 'system');
    expect(s.results, isEmpty);
    expect(s.examsUsed, 0);
    expect(s.premium, isFalse);
  });

  test('yaz ve geri oku', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SaveStore s = await SaveStore.open();
    await s.setResults(<String, bool>{'1': true, 'berlin-2': false});
    await s.setExamsUsed(2);
    await s.setPremium(true);
    final SaveStore again = await SaveStore.open();
    expect(again.results, <String, bool>{'1': true, 'berlin-2': false});
    expect(again.examsUsed, 2);
    expect(again.premium, isTrue);
  });

  test('bozuk kayıt çökertmez', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'results': '{bozuk'});
    final SaveStore s = await SaveStore.open();
    expect(s.results, isEmpty);
  });
}
