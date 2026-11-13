// "Klarheit" görsel kimliği: ölçüler, yazı stilleri, tema ve ortak küçük bileşenler.
// Renkler renk.dart'ta (tasarim/tokens.json'dan üretilir).
import 'package:flutter/material.dart';

import 'renk.dart';

export 'renk.dart';

/// Boşluk ölçeği (dp). Widget'lardaki dolgu ve aralıklar yalnızca bu değerleri kullanır.
abstract final class Bosluk {
  static const double b2 = 2, b3 = 3, b4 = 4, b6 = 6, b8 = 8, b10 = 10, b11 = 11, b12 = 12;
  static const double b14 = 14, b16 = 16, b18 = 18, b24 = 24, b32 = 32, b40 = 40;
}

/// Köşe yarıçapları, role göre.
abstract final class Kose {
  /// Etiket, şerit kutusu, "Koçu" etiketi.
  static const double etiket = 4;

  /// İlerleme çubuğu (10 dp yüksekliğin yarısı).
  static const double cubuk = 5;

  /// Düğme, şık, açılır liste, dil tuşu.
  static const double kontrol = 6;

  /// Kart.
  static const double kart = 8;
}

/// Sabit ölçüler.
abstract final class Olcu {
  /// En küçük dokunma alanı.
  static const double dokunma = 48;
}

/// Yazı stilleri. Renk vermez: rengi kullanan yer `copyWith(color: ...)` ile ekler.
abstract final class Yazi {
  static const _tablo = [FontFeature.tabularFigures()];
  static const puan = TextStyle(fontSize: 44, fontWeight: FontWeight.w800, height: 1, fontFeatures: _tablo);
  static const hero = TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.15);
  static const marka = TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1);
  static const baslikBuyuk = TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.2);
  static const baslikOrta = TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.3);
  static const sayac = TextStyle(fontSize: 22, fontWeight: FontWeight.w800, fontFeatures: _tablo);
  static const dilAdi = TextStyle(fontSize: 22, fontWeight: FontWeight.w700);
  static const soru = TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.35);
  static const baslik = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.3);
  static const secenek = TextStyle(fontSize: 17, height: 1.4);
  static const eyalet = TextStyle(fontSize: 17);
  static const dugme = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
  static const govde = TextStyle(fontSize: 16, height: 1.5);
  static const soluk = TextStyle(fontSize: 15, height: 1.4);
  static const altBilgi = TextStyle(fontSize: 14, height: 1.4);
  static const dilKisa = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
  static const etiket = TextStyle(fontSize: 13, fontWeight: FontWeight.w700);
  static const etiketKucuk = TextStyle(fontSize: 12, fontWeight: FontWeight.w700);
}

/// Uygulamaya paketlenmiş tek yazı ailesi (Latin + Arapça), assets/fonts/ içinde.
const String _yaziAilesi = 'Cairo';

ThemeData temaOlustur(Brightness b) {
  final r = b == Brightness.dark ? Renk.koyu : Renk.acik;
  final cs = ColorScheme(
    brightness: b,
    primary: r.vurgu,
    onPrimary: r.vurguUstu,
    secondary: r.isaret,
    onSecondary: r.isaretUstu,
    error: r.yanlis,
    onError: r.sayfa,
    surface: r.sayfa,
    onSurface: r.yazi,
    outline: r.cizgi,
  );
  final sekil = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Kose.kontrol));
  const yazi = Yazi.dugme;
  const dolgu = EdgeInsets.symmetric(horizontal: Bosluk.b16, vertical: Bosluk.b12);
  final base = ThemeData(useMaterial3: true, colorScheme: cs, fontFamily: _yaziAilesi);
  return base.copyWith(
    scaffoldBackgroundColor: r.kagit,
    canvasColor: r.sayfa,
    // Gövde metni: Material varsayılanı 14 px yerine 16 px / 1.5 (Almanca ve uzun açıklamalar için okunurluk).
    textTheme: base.textTheme
        .apply(bodyColor: r.yazi, displayColor: r.yazi, fontFamily: _yaziAilesi)
        .copyWith(bodyMedium: base.textTheme.bodyMedium?.merge(Yazi.govde)),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, Olcu.dokunma),
        padding: dolgu,
        shape: sekil,
        textStyle: yazi,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, Olcu.dokunma),
        padding: dolgu,
        shape: sekil,
        foregroundColor: r.vurgu,
        side: BorderSide(color: r.vurgu, width: 1.5),
        textStyle: yazi,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(64, Olcu.dokunma),
        foregroundColor: r.vurgu,
        shape: sekil,
        textStyle: yazi,
      ),
    ),
  );
}

/// Sayfa kartı: beyaz zemin, ince çizgi, 8 yarıçap.
class Kart extends StatelessWidget {
  const Kart({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final r = Renk.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Bosluk.b16),
      decoration: BoxDecoration(
        color: r.sayfa,
        border: Border.all(color: r.cizgi),
        borderRadius: BorderRadius.circular(Kose.kart),
      ),
      child: child,
    );
  }
}

/// Sarı işaret etiketi (ör. güncel bilgi uyarısı).
class Etiket extends StatelessWidget {
  const Etiket(this.metin, {super.key, this.zemin, this.yazi, this.kucuk = false});
  final String metin;
  final Color? zemin;
  final Color? yazi;
  final bool kucuk;

  @override
  Widget build(BuildContext context) {
    final r = Renk.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Bosluk.b8, vertical: Bosluk.b2),
      decoration: BoxDecoration(color: zemin ?? r.isaret, borderRadius: BorderRadius.circular(Kose.etiket)),
      child: Text(
        metin,
        style: (kucuk ? Yazi.etiketKucuk : Yazi.etiket).copyWith(color: yazi ?? r.isaretUstu),
      ),
    );
  }
}

class Baslik extends StatelessWidget {
  const Baslik(this.metin, {super.key});
  final String metin;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(metin, style: Yazi.baslik),
      );
}

class SolukMetin extends StatelessWidget {
  const SolukMetin(this.metin, {super.key, this.boyut = 15});
  final String metin;
  final double boyut;

  @override
  Widget build(BuildContext context) =>
      Text(metin, style: Yazi.soluk.copyWith(fontSize: boyut, color: Renk.of(context).soluk));
}

/// Almanca metin: her zaman soldan sağa.
class Almanca extends StatelessWidget {
  const Almanca(this.metin, {super.key, this.stil});
  final String metin;
  final TextStyle? stil;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Text(metin, textAlign: TextAlign.start, style: stil),
      );
}

/// Çerçeveli açılır liste (en az 48dp yükseklik).
class Acilir<T> extends StatelessWidget {
  const Acilir({super.key, required this.deger, required this.ogeler, required this.degisti, this.etiket});
  final T deger;
  final List<DropdownMenuItem<T>> ogeler;
  final ValueChanged<T> degisti;
  final String? etiket;

  @override
  Widget build(BuildContext context) {
    final r = Renk.of(context);
    return Semantics(
      label: etiket,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Bosluk.b12),
        decoration: BoxDecoration(
          color: r.sayfa,
          // Kontrol sınırı en az 3:1 olmalı: cizgi (1,4:1) yerine secenekKenar (4,1:1 / 4,8:1).
          border: Border.all(color: r.secenekKenar, width: 1.5),
          borderRadius: BorderRadius.circular(Kose.kontrol),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isExpanded: true,
            value: deger,
            items: ogeler,
            onChanged: (v) {
              if (v != null) degisti(v);
            },
          ),
        ),
      ),
    );
  }
}

/// Kabuktaki kaydırma denetleyicisini alt ağaca verir.
class KaydirmaKapsami extends InheritedWidget {
  const KaydirmaKapsami({super.key, required this.denetleyici, required super.child});
  final ScrollController denetleyici;

  @override
  bool updateShouldNotify(KaydirmaKapsami old) => denetleyici != old.denetleyici;
}

/// Sayfanın en üstüne atlar (soru değişince).
void ustuneKaydir(BuildContext context) {
  final c = context.getInheritedWidgetOfExactType<KaydirmaKapsami>()?.denetleyici;
  if (c != null && c.hasClients) c.jumpTo(0);
}
