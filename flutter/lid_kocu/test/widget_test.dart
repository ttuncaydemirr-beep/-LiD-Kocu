import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lid_kocu/state.dart';
import 'package:lid_kocu/ui/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _kur(WidgetTester t) async {
  SharedPreferences.setMockInitialValues({});
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
  });
}
