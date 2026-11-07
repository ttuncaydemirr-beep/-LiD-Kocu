import 'package:flutter_test/flutter_test.dart';
import 'package:lid_kocu/core/models.dart';
import 'package:lid_kocu/data/app_data.dart';

import 'helpers.dart';

void main() {
  late AppData data;
  setUpAll(() async {
    data = await loadData();
  });

  test('katalog: 300 genel + 16 eyalet x 10 soru', () {
    expect(data.catalog.general.length, 300);
    expect(data.catalog.states.length, 16);
    for (final StateInfo s in data.catalog.states) {
      expect(s.questions.length, 10, reason: s.id);
    }
    expect(data.catalog.totalQuestions, 460);
    expect(data.catalog.stand, '2025-05-07');
  });

  test('her sorunun 4 seçeneği ve 0-3 arası doğru cevabı var; kimlikler benzersiz', () {
    final Set<String> ids = <String>{};
    final List<Question> all = <Question>[
      ...data.catalog.general,
      for (final StateInfo s in data.catalog.states) ...s.questions,
    ];
    for (final Question q in all) {
      expect(q.options.length, 4, reason: q.id);
      expect(q.correct, inInclusiveRange(0, 3), reason: q.id);
      expect(q.de.trim(), isNotEmpty, reason: q.id);
      expect(ids.add(q.id), isTrue, reason: 'kopya kimlik ${q.id}');
    }
    expect(ids.length, 460);
  });

  test('eyalet soruları kendi eyaletine bağlı, genel sorular değil', () {
    for (final StateInfo s in data.catalog.states) {
      for (final Question q in s.questions) {
        expect(q.stateId, s.id);
        expect(q.isState, isTrue);
      }
    }
    expect(data.catalog.general.every((Question q) => !q.isState), isTrue);
    expect(data.catalog.pool('berlin').length, 310);
  });

  test('her soru için tr/en/ar çeviri (soru, 4 seçenek, açıklama) ve Almanca açıklama var', () {
    expect(data.translations.length, 460);
    for (final String lang in <String>['tr', 'en', 'ar']) {
      for (final String id in <String>[
        ...data.catalog.general.map((Question q) => q.id),
        for (final StateInfo s in data.catalog.states) ...s.questions.map((Question q) => q.id),
      ]) {
        final QuestionText? t = data.translations.of(id, lang);
        expect(t, isNotNull, reason: '$id/$lang');
        expect(t!.q, isNotEmpty, reason: '$id/$lang');
        expect(t.o?.length, 4, reason: '$id/$lang');
        expect(t.x, isNotEmpty, reason: '$id/$lang');
      }
    }
    expect(data.translations.german('1')?.x, isNotEmpty);
  });

  test('resimli sorularda resim açıklaması var (1 ya da 4 öğe, dört dilde aynı sayıda)', () {
    int withPicture = 0;
    for (final Question q in <Question>[
      ...data.catalog.general,
      for (final StateInfo s in data.catalog.states) ...s.questions,
    ]) {
      final int? n = data.translations.german(q.id)?.g?.length;
      if (n == null) {
        expect(q.options.any((String o) => o.startsWith('Bild ')), isFalse, reason: q.id);
        continue;
      }
      withPicture++;
      expect(<int>[1, 4], contains(n), reason: q.id);
      for (final String lang in <String>['tr', 'en', 'ar']) {
        expect(data.translations.of(q.id, lang)?.g?.length, n, reason: '${q.id}/$lang');
      }
    }
    expect(withPicture, 43);
  });

  test('brandenburg-1: işaretli doğru cevap kırmızı kartal', () {
    final Question q = data.catalog.byId('brandenburg-1')!;
    final String correct = data.translations.german('brandenburg-1')!.g![q.correct];
    expect(correct, contains('roten Adler'));
  });

  test('cevabı değişebilen sorular işaretli', () {
    for (final String id in <String>['72', '73', '75', '236']) {
      expect(data.catalog.byId(id)!.dated, isTrue, reason: id);
    }
    expect(data.catalog.byId('saarland-4')!.dated, isTrue);
    expect(data.catalog.byId('1')!.dated, isFalse);
  });
}
