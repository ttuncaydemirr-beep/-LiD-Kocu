import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:lid_kocu/core/veri.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Katalog katalog;
  late Ceviriler ceviriler;

  setUpAll(() async {
    katalog = Katalog.json(jsonDecode(await rootBundle.loadString('assets/katalog.json')) as Map<String, dynamic>);
    ceviriler = Ceviriler(jsonDecode(await rootBundle.loadString('assets/ceviriler.json')) as Map<String, dynamic>);
  });

  test('katalog: 300 genel ve 16 eyalet x 10 soru', () {
    expect(katalog.genel.length, 300);
    expect(katalog.eyaletler.length, 16);
    for (final e in katalog.eyaletler.values) {
      expect(e.sorular.length, 10, reason: e.ad);
    }
    for (final s in [...katalog.genel, for (final e in katalog.eyaletler.values) ...e.sorular]) {
      expect(s.secenekler.length, 4, reason: s.id);
      expect(s.dogru, inInclusiveRange(0, 3), reason: s.id);
    }
  });

  test('sinavSec: 500 denemede 33 benzersiz soru, 3 eyalet sorusu', () {
    final rng = Random(42);
    final genelIds = katalog.genel.map((s) => s.id).toSet();
    final eyalet = katalog.eyaletler.keys.first;
    final eyaletIds = katalog.eyaletler[eyalet]!.sorular.map((s) => s.id).toSet();
    for (var i = 0; i < 500; i++) {
      final sec = katalog.sinavSec(eyalet, rng);
      final ids = sec.map((s) => s.id).toList();
      expect(sec.length, sinavSoruSayisi);
      expect(ids.toSet().length, sinavSoruSayisi);
      expect(ids.where(eyaletIds.contains).length, eyaletSoruSayisi);
      expect(ids.where(genelIds.contains).length, genelSoruSayisi);
    }
  });

  test('puan: 16 kaldi, 17 gecti', () {
    final sorular = katalog.sinavSec('berlin', Random(1));
    Sinav kur(int dogru) {
      final x = Sinav(sorular, DateTime.now());
      for (var i = 0; i < sorular.length; i++) {
        x.cevaplar[i] = i < dogru ? sorular[i].dogru : (sorular[i].dogru + 1) % 4;
      }
      return x;
    }

    expect(kur(16).puan, 16);
    expect(kur(16).gecti, isFalse);
    expect(kur(17).puan, 17);
    expect(kur(17).gecti, isTrue);
    expect(Sinav(sorular, DateTime.now()).bos, sinavSoruSayisi);
  });

  test('her soruda tr/en/ar cevirisinde 4 sik var', () {
    final hepsi = [...katalog.genel, for (final e in katalog.eyaletler.values) ...e.sorular];
    for (final s in hepsi) {
      for (final dil in const ['tr', 'en', 'ar']) {
        final c = ceviriler.al(s.id, dil);
        expect(c, isNotNull, reason: '${s.id} $dil');
        expect(c!.secenekler.length, 4, reason: '${s.id} $dil');
      }
    }
  });
}
