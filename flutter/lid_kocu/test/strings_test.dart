import 'package:flutter_test/flutter_test.dart';
import 'package:lid_kocu/core/strings.dart';
import 'package:lid_kocu/data/app_data.dart';

import 'helpers.dart';

void main() {
  late AppData data;
  setUpAll(() async {
    data = await loadData();
  });

  test('arayüz anahtarları dört dilde eşit', () {
    final Strings s = data.strings;
    expect(s.languages.toSet(), <String>{'tr', 'en', 'de', 'ar'});
    final Set<String> base = s.keysOf('tr').toSet();
    expect(base.length, greaterThan(60));
    for (final String l in <String>['en', 'de', 'ar']) {
      expect(s.keysOf(l).toSet(), base, reason: l);
    }
  });

  test('yer tutucular doldurulur', () {
    expect(data.strings.t('en', 'q', <String, Object>{'a': 3, 'b': 33}), 'Question 3 of 33');
    expect(data.strings.t('tr', 'score', <String, Object>{'n': 17}), '33 sorudan 17 doğru. Geçmek için 17 gerekiyor.');
  });

  test('eksik anahtar Türkçeye, o da yoksa anahtarın kendisine düşer', () {
    const Strings s = Strings(<String, Map<String, String>>{
      'tr': <String, String>{'a': 'Merhaba {n}'},
      'en': <String, String>{},
    });
    expect(s.t('en', 'a', <String, Object>{'n': 2}), 'Merhaba 2');
    expect(s.t('en', 'yok'), 'yok');
  });

  test('hiçbir metinde doldurulmamış yer tutucu kalmaz (parametre verilince)', () {
    final RegExp ph = RegExp(r'\{(\w+)\}');
    for (final String l in <String>['tr', 'en', 'de', 'ar']) {
      for (final String k in data.strings.keysOf('tr')) {
        final String raw = data.strings.t(l, k);
        final Map<String, Object> params = <String, Object>{for (final RegExpMatch m in ph.allMatches(raw)) m.group(1)!: 1};
        expect(ph.hasMatch(data.strings.t(l, k, params)), isFalse, reason: '$l.$k');
      }
    }
  });
}
