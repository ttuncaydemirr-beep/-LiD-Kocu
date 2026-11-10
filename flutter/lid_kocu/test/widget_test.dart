import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lid_kocu/core/veri.dart';
import 'package:lid_kocu/state.dart';
import 'package:lid_kocu/ui/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _kur(WidgetTester t, [Map<String, Object> ilk = const {'kurulum': true}]) async {
  SharedPreferences.setMockInitialValues(ilk);
  final s = await t.runAsync(() => AppState.olustur(sesli: false));
  return s!;
}

void _genisYuzey(WidgetTester t) {
  t.view.physicalSize = const Size(800, 3200);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('uygulama aciliyor', (t) async {
    _genisYuzey(t);
    final s = await _kur(t);
    s.dilSec('tr');
    await t.pumpWidget(LidKocuApp(state: s));
    await t.pumpAndSettle();
    expect(find.text('Koçu'), findsOneWidget);
    expect(find.text(s.t('hero')), findsOneWidget);
    expect(find.byKey(const ValueKey('soru-de')), findsOneWidget);
  });

  testWidgets('dort dil arasinda gecis', (t) async {
    _genisYuzey(t);
    final s = await _kur(t);
    await t.pumpWidget(LidKocuApp(state: s));
    await t.pumpAndSettle();
    final basliklar = <String>{};
    for (final d in diller) {
      await t.tap(find.byKey(ValueKey('dil-$d')));
      await t.pumpAndSettle();
      expect(s.dil, d);
      final hero = s.t('hero');
      expect(find.text(hero), findsOneWidget);
      basliklar.add(hero);
    }
    expect(basliklar.length, 4);
  });

  testWidgets('arapcada rtl, Almanca soru ltr', (t) async {
    _genisYuzey(t);
    final s = await _kur(t);
    await t.pumpWidget(LidKocuApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('dil-ar')));
    await t.pumpAndSettle();
    expect(Directionality.of(t.element(find.byKey(const ValueKey('sekme-calis')))), TextDirection.rtl);
    // Almanca metnin kendisi (Almanca bileşeninin içindeki Text) her dilde soldan sağa.
    final deMetin = find.descendant(of: find.byKey(const ValueKey('soru-de')), matching: find.byType(Text)).first;
    expect(Directionality.of(t.element(deMetin)), TextDirection.ltr);
    await t.tap(find.byKey(const ValueKey('dil-tr')));
    await t.pumpAndSettle();
    expect(Directionality.of(t.element(find.byKey(const ValueKey('sekme-calis')))), TextDirection.ltr);
  });

  testWidgets('sinav: 33 soru cevapla, bitir, sonuc ekrani', (t) async {
    _genisYuzey(t);
    final s = await _kur(t);
    s.dilSec('en');
    await t.pumpWidget(LidKocuApp(state: s));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const ValueKey('sekme-sinav')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('basla')));
    await t.pumpAndSettle();
    expect(s.sinav, isNotNull);
    expect(find.byKey(const ValueKey('sayac')), findsOneWidget);

    for (var i = 0; i < 33; i++) {
      await t.tap(find.byKey(const ValueKey('secenek-0')));
      await t.pump();
    }
    expect(s.sinav!.bos, 0);

    await t.tap(find.byKey(const ValueKey('bitir')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('sonuc')), findsOneWidget);
    expect(t.widget<Text>(find.byKey(const ValueKey('puan'))).data, '${s.sinav!.puan} / 33');
    expect(find.byKey(const ValueKey('tekrar')), findsOneWidget);
    expect(find.byKey(const ValueKey('sayac')), findsNothing);

    // Satış anı: yanlış sayısı, "Yanlışlarını çalış" ve Premium teklifi.
    final yanlis = 33 - s.sinav!.puan;
    expect(yanlis, greaterThan(0));
    expect(find.text(s.t('wrongCount', {'n': yanlis})), findsOneWidget);
    expect(find.byKey(const ValueKey('sonuc-teklif')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('yanlis-calis')));
    await t.pumpAndSettle();
    expect(s.calisFiltre, filtreSinav);
    expect(find.text(s.t('q', {'a': 1, 'b': yanlis})), findsOneWidget);
    expect(find.text(s.t('wrongsCount', {'n': yanlis})), findsOneWidget);
    // İlk 3 yanlışın açıklaması ücretsiz: cevaplayınca kilit düğmesi çıkmaz.
    await t.tap(find.byKey(const ValueKey('secenek-0')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('premium-ac')), findsNothing);
  });

  testWidgets('bos soru varken bitir onay ister; vazgecince sinav surer', (t) async {
    _genisYuzey(t);
    final s = await _kur(t);
    s.dilSec('tr');
    await t.pumpWidget(LidKocuApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('sekme-sinav')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('basla')));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const ValueKey('bitir')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('bitir-dialog')), findsOneWidget);
    expect(find.text(s.t('confirmFinishBody', {'n': 33})), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('bitir-vazgec')));
    await t.pumpAndSettle();
    expect(s.sinav!.bitti, isFalse);
    expect(s.sinavSayisi, 0);

    await t.tap(find.byKey(const ValueKey('bitir')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('bitir-onay')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('sonuc')), findsOneWidget);
    expect(s.sinavSayisi, 1);
  });

  testWidgets('ana sayfadan sinava basla devam eden sinavi silmez', (t) async {
    _genisYuzey(t);
    final s = await _kur(t);
    await t.pumpWidget(LidKocuApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('basla-ana')));
    await t.pumpAndSettle();
    final ilk = s.sinav;
    await t.tap(find.byKey(const ValueKey('secenek-0')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('sekme-ana')));
    await t.pumpAndSettle();
    expect(find.text(s.t('continueExam')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('basla-ana')));
    await t.pumpAndSettle();
    expect(identical(s.sinav, ilk), isTrue);
    expect(s.sinav!.cevaplar.first, 0);
  });

  testWidgets('ilk acilis: dil + eyalet secimi, uyari, sonra ana sayfa', (t) async {
    _genisYuzey(t);
    final s = await _kur(t, const {});
    await t.pumpWidget(LidKocuApp(state: s));
    await t.pumpAndSettle();
    expect(s.kurulumTamam, isFalse);
    for (final d in diller) {
      expect(find.byKey(ValueKey('kur-dil-$d')), findsOneWidget);
    }
    expect(find.text(s.t('hero')), findsNothing);

    // Arapçada kurulum ekranı da sağdan sola.
    await t.tap(find.byKey(const ValueKey('kur-dil-ar')));
    await t.pumpAndSettle();
    expect(Directionality.of(t.element(find.byKey(const ValueKey('kurulum-devam')))), TextDirection.rtl);

    await t.tap(find.byKey(const ValueKey('kur-dil-tr')));
    await t.pumpAndSettle();
    expect(s.dil, 'tr');
    await t.tap(find.byKey(const ValueKey('kurulum-devam')));
    await t.pumpAndSettle();
    expect(find.text(s.t('dis')), findsWidgets);

    // Eyalet seçilmeden başlanamaz.
    await t.tap(find.byKey(const ValueKey('kurulum-bitir')));
    await t.pumpAndSettle();
    expect(s.kurulumTamam, isFalse);

    await t.tap(find.byKey(const ValueKey('kur-eyalet-bayern')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('kurulum-bitir')));
    await t.pumpAndSettle();
    expect(s.kurulumTamam, isTrue);
    expect(s.eyalet, 'bayern');
    expect(find.text(s.t('hero')), findsOneWidget);

    final p = await SharedPreferences.getInstance();
    expect(p.getBool('kurulum'), isTrue);
    final s2 = await t.runAsync(() => AppState.olustur(sesli: false));
    expect(s2!.kurulumTamam, isTrue);
    expect(s2.eyalet, 'bayern');
  });

  testWidgets('calisma konumu sekme degisince ve yeniden acilinca korunur', (t) async {
    _genisYuzey(t);
    final s = await _kur(t);
    s.dilSec('tr');
    await t.pumpWidget(LidKocuApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('sekme-calis')));
    await t.pumpAndSettle();
    final n = s.havuz.length;
    expect(find.text(s.t('q', {'a': 1, 'b': n})), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('secenek-0')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('sonraki-soru')));
    await t.pumpAndSettle();
    expect(find.text(s.t('q', {'a': 2, 'b': n})), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('sekme-ana')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('sekme-calis')));
    await t.pumpAndSettle();
    expect(find.text(s.t('q', {'a': 2, 'b': n})), findsOneWidget);

    final s2 = await t.runAsync(() => AppState.olustur(sesli: false));
    expect(s2!.calisBaslangic(filtreTumu, s2.calismaListesi(filtreTumu)), 1);
  });

  testWidgets('yanlislarim: ilk 3 soru kimlikle ucretsiz, karisik sira baska soru acmaz, sonra kilit', (t) async {
    _genisYuzey(t);
    final s = await _kur(t);
    // Ücretsiz örnek (kimlik <= 20) ve günün sorusu olmayan 5 soruyu yanlış işaretle.
    final yanlis = s.havuz.where((q) => !ornekAciklama(q.id) && q.id != s.gununSorusu.id).take(5).toList();
    expect(yanlis.length, 5);
    for (final q in yanlis) {
      s.cevapla(q, (q.dogru + 1) % 4);
    }
    expect([for (final q in yanlis) s.aciklamaAcik(q)], everyElement(isFalse));

    // İlk ziyaret: listedeki ilk 3 soru kümeye girer.
    final ilk = s.calismaListesi(filtreYanlis);
    expect(ilk.length, 5);
    final acik = [for (final q in ilk.take(3)) q.id];
    List<String> acikOlanlar() => [for (final q in yanlis) if (s.yanlisUcretsiz(q)) q.id]..sort();
    expect(acikOlanlar(), [...acik]..sort());

    // Karışık sırayı defalarca aç/kapa: başka soru açılmaz.
    for (var i = 0; i < 8; i++) {
      s.karisikSec(true);
      s.calismaListesi(filtreYanlis);
      expect(acikOlanlar(), [...acik]..sort());
      s.karisikSec(false);
      s.calismaListesi(filtreYanlis);
      expect(acikOlanlar(), [...acik]..sort());
    }
    for (final q in yanlis) {
      expect(s.aciklamaAcik(q), acik.contains(q.id));
    }

    await t.pumpWidget(LidKocuApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('sekme-calis')));
    await t.pumpAndSettle();
    s.calisFiltreSec(filtreYanlis);
    await t.pumpAndSettle();
    expect(find.text(s.t('wrongsCount', {'n': 5})), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(const ValueKey('yanlis-kilit')), findsNothing);
      await t.tap(find.byKey(const ValueKey('secenek-0')));
      await t.pumpAndSettle();
      // Kimliği açılmış sorunun açıklaması kilitli değil.
      expect(find.byKey(const ValueKey('premium-ac')), findsNothing);
      await t.tap(find.byKey(const ValueKey('sonraki-soru')));
      await t.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('yanlis-kilit')), findsOneWidget);
    expect(find.text(s.t('lockedRest', {'n': 2})), findsOneWidget);

    // Kalıcı: yeniden açılışta aynı kimlikler açık.
    final s2 = await t.runAsync(() => AppState.olustur(sesli: false));
    for (final q in yanlis) {
      expect(s2!.yanlisUcretsiz(q), acik.contains(q.id));
    }
  });

  testWidgets('dinle dugmesi ucretsiz kullaniciya kilitli gorunur', (t) async {
    _genisYuzey(t);
    final s = await _kur(t);
    s.dilSec('de');
    await t.pumpWidget(LidKocuApp(state: s));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('dinle')), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('dinle')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('satin-al')), findsOneWidget);
  });
}
