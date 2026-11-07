import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lid_kocu/core/exam.dart';
import 'package:lid_kocu/core/models.dart';
import 'package:lid_kocu/data/app_data.dart';
import 'package:lid_kocu/services/billing_service.dart';
import 'package:lid_kocu/services/save_store.dart';
import 'package:lid_kocu/state/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  late AppData data;
  setUpAll(() async {
    data = await loadData();
  });

  late DateTime now;
  late FakeBilling billing;
  late FakeSpeech speech;

  Future<AppController> make({Map<String, Object> prefs = const <String, Object>{}, String? device, bool owned = false}) async {
    SharedPreferences.setMockInitialValues(prefs);
    now = DateTime.utc(2026, 11, 8, 12);
    billing = FakeBilling(owned: owned);
    speech = FakeSpeech();
    return AppController(
      data: data,
      store: await SaveStore.open(),
      billing: billing,
      speech: speech,
      random: Random(42),
      clock: () => now,
      deviceLanguage: device,
    );
  }

  Future<void> answerAllCorrect(AppController c) async {
    final ExamSession e = c.exam!;
    for (int i = 0; i < e.questions.length; i++) {
      c.goToExamQuestion(i);
      c.answerExam(e.questions[i].correct);
    }
  }

  test('varsayılanlar: telefon dili desteklenirse o, değilse Türkçe; eyalet Berlin; tema sistem', () async {
    final AppController c = await make(device: 'ar');
    expect(c.lang, 'ar');
    expect(c.isRtl, isTrue);
    expect(c.stateId, 'berlin');
    expect(c.themeMode, ThemeMode.system);
    c.dispose();
    final AppController d = await make(device: 'fr');
    expect(d.lang, 'tr');
    expect(d.isRtl, isFalse);
    d.dispose();
  });

  test('dil, eyalet ve tema kalıcı kaydedilir', () async {
    final AppController c = await make();
    await c.setLang('de');
    await c.setStateId('bayern');
    await c.setThemeMode(ThemeMode.dark);
    final SaveStore again = await SaveStore.open();
    expect(again.lang, 'de');
    expect(again.stateId, 'bayern');
    expect(again.theme, 'dark');
    expect(c.t('home'), 'Start');
    await c.setLang('xx'); // desteklenmeyen dil yok sayılır
    expect(c.lang, 'de');
    c.dispose();
  });

  test('ücretsiz kullanıcı: 2 deneme sınavı, üçüncüsü reddedilir', () async {
    final AppController c = await make();
    expect(c.examsLeft, 2);
    expect(c.startExam(), isTrue);
    expect(c.exam!.questions.length, 33);
    await c.finishExam();
    expect(c.examsUsed, 1);
    expect(c.examsLeft, 1);
    expect(c.startExam(), isTrue);
    await c.finishExam();
    expect(c.examsUsed, 2);
    expect(c.examsLeft, 0);
    expect(c.canStartExam, isFalse);
    final ExamSession last = c.exam!;
    expect(c.startExam(), isFalse);
    expect(identical(c.exam, last), isTrue, reason: 'reddedilen başlatma mevcut sınavı bozmamalı');
    c.dispose();
  });

  test('bitirilmeyen sınav hakkı harcamaz; hak kalıcıdır', () async {
    final AppController c = await make();
    expect(c.startExam(), isTrue);
    expect(c.examsUsed, 0);
    await c.finishExam();
    expect((await SaveStore.open()).examsUsed, 1);
    c.dispose();
    final AppController d = await make(prefs: <String, Object>{'examsUsed': 2});
    expect(d.canStartExam, isFalse);
    d.dispose();
  });

  test('premium: sınırsız deneme sınavı', () async {
    final AppController c = await make(owned: true, prefs: <String, Object>{'premium': true, 'examsUsed': 50});
    expect(c.premium, isTrue);
    expect(c.examsLeft, isNull);
    expect(c.canStartExam, isTrue);
    expect(c.startExam(), isTrue);
    c.dispose();
  });

  test('premium satın alma: hak açılır ve kaydedilir; iptalde açılmaz', () async {
    final AppController c = await make(prefs: <String, Object>{'examsUsed': 2});
    expect(c.canStartExam, isFalse);
    billing.nextOutcome = PurchaseOutcome.cancelled;
    expect(await c.buyPremium(), PurchaseOutcome.cancelled);
    expect(c.premium, isFalse);
    billing.nextOutcome = PurchaseOutcome.pending;
    expect(await c.buyPremium(), PurchaseOutcome.pending);
    expect(c.premium, isFalse);
    billing.nextOutcome = PurchaseOutcome.purchased;
    expect(await c.buyPremium(), PurchaseOutcome.purchased);
    expect(c.premium, isTrue);
    expect(c.canStartExam, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect((await SaveStore.open()).premium, isTrue);
    c.dispose();
  });

  test('satın alma geri yükleme: bulundu / bulunamadı / ulaşılamadı', () async {
    final AppController c = await make();
    billing.restoreResult = null;
    expect(await c.restorePremium(), isNull);
    expect(c.premium, isFalse);
    billing.restoreResult = false;
    expect(await c.restorePremium(), isFalse);
    billing.restoreResult = true;
    expect(await c.restorePremium(), isTrue);
    expect(c.premium, isTrue);
    c.dispose();
  });

  test('sınav sonucu: 33 doğru geçer; cevaplar ilerlemeye işlenir', () async {
    final AppController c = await make();
    c.startExam();
    await answerAllCorrect(c);
    expect(c.exam!.unanswered, 0);
    await c.finishExam();
    expect(c.exam!.over, isTrue);
    expect(c.exam!.score, 33);
    expect(c.exam!.passed, isTrue);
    for (final Question q in c.exam!.questions) {
      expect(c.results[q.id], isTrue);
    }
    expect((await SaveStore.open()).results.length, 33);
    c.dispose();
  });

  test('süre dolunca sınav biter ve timedOut işaretlenir; boş sorular yanlış sayılır', () async {
    final AppController c = await make();
    c.startExam();
    c.goToExamQuestion(0);
    c.answerExam(c.exam!.questions[0].correct);
    now = now.add(const Duration(minutes: 61));
    expect(c.exam!.secondsLeft(now), 0);
    await c.finishExam(timedOut: true);
    expect(c.exam!.timedOut, isTrue);
    expect(c.exam!.score, 1);
    expect(c.exam!.passed, isFalse);
    c.dispose();
  });

  test('ilerleme: kaydet, yanlışlarım listesi, sıfırla (deneme hakkı korunur)', () async {
    final AppController c = await make(prefs: <String, Object>{'examsUsed': 1});
    final Question q1 = c.catalog.general[0];
    final Question q2 = c.catalog.general[1];
    await c.record(q1, true);
    await c.record(q2, false);
    expect(c.correctCount, 1);
    expect(c.studyList('wrongs').map((Question q) => q.id), <String>[q2.id]);
    expect(c.studyList('all').length, 310);
    await c.resetProgress();
    expect(c.correctCount, 0);
    expect(c.studyList('wrongs'), isEmpty);
    expect(c.examsUsed, 1);
    c.dispose();
  });

  test('bugünün sorusu güne göre döner ve genel sorulardandır', () async {
    final AppController c = await make();
    final Question a = c.todayQuestion;
    expect(a.isState, isFalse);
    now = now.add(const Duration(days: 1));
    expect(c.todayQuestion.id, isNot(a.id));
    c.dispose();
  });

  test('sesli okuma: soru ve seçenekler Almanca okunur; Almanca ses yoksa false', () async {
    final AppController c = await make();
    final Question q = c.catalog.general[0];
    expect(await c.speak(q), isTrue);
    expect(speech.spoken.single, contains(q.de));
    expect(speech.spoken.single, contains('A: ${q.options[0]}'));
    speech.germanAvailable = false;
    expect(await c.speak(q), isFalse);
    c.dispose();
  });
}
