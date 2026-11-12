// Renk belirteçleri ("Klarheit" görsel kimliği), tema ve ortak küçük bileşenler.
// Metin/zemin çiftleri WCAG AA (4.5:1), şık çerçevesi ve vurgu çizgileri en az 3:1 sağlar.
import 'package:flutter/material.dart';

@immutable
class Renk {
  final Color kagit, sayfa, yazi, soluk, cizgi, secenekKenar, vurgu, vurguUstu, isaret, isaretUstu;
  final Color dogru, dogruZemin, yanlis, yanlisZemin;
  const Renk({
    required this.kagit,
    required this.sayfa,
    required this.yazi,
    required this.soluk,
    required this.cizgi,
    required this.secenekKenar,
    required this.vurgu,
    required this.vurguUstu,
    required this.isaret,
    required this.isaretUstu,
    required this.dogru,
    required this.dogruZemin,
    required this.yanlis,
    required this.yanlisZemin,
  });

  static const Renk acik = Renk(
    kagit: Color(0xFFF3F6FB),
    sayfa: Color(0xFFFFFFFF),
    yazi: Color(0xFF14233B),
    soluk: Color(0xFF566479),
    cizgi: Color(0xFFD3DBE6),
    secenekKenar: Color(0xFF6E7F9B),
    vurgu: Color(0xFF1A47A8),
    vurguUstu: Color(0xFFFFFFFF),
    isaret: Color(0xFFFFC83D),
    isaretUstu: Color(0xFF2A2100),
    dogru: Color(0xFF0D7A4F),
    dogruZemin: Color(0xFFDFF5EA),
    yanlis: Color(0xFFB3261E),
    yanlisZemin: Color(0xFFFDE7E5),
  );

  static const Renk koyu = Renk(
    kagit: Color(0xFF0F1726),
    sayfa: Color(0xFF182235),
    yazi: Color(0xFFE9EEF6),
    soluk: Color(0xFFA3B0C4),
    cizgi: Color(0xFF2E3B52),
    secenekKenar: Color(0xFF7D8EAB),
    vurgu: Color(0xFF8AABF0),
    vurguUstu: Color(0xFF0B1630),
    isaret: Color(0xFFFFC83D),
    isaretUstu: Color(0xFF2A2100),
    dogru: Color(0xFF5FD6A4),
    dogruZemin: Color(0xFF12382A),
    yanlis: Color(0xFFFF9D94),
    yanlisZemin: Color(0xFF47201D),
  );

  static Renk of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? koyu : acik;
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
  final sekil = RoundedRectangleBorder(borderRadius: BorderRadius.circular(6));
  const yazi = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
  const dolgu = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  final base = ThemeData(useMaterial3: true, colorScheme: cs, fontFamily: _yaziAilesi);
  return base.copyWith(
    scaffoldBackgroundColor: r.kagit,
    canvasColor: r.sayfa,
    textTheme: base.textTheme.apply(bodyColor: r.yazi, displayColor: r.yazi, fontFamily: _yaziAilesi),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: dolgu,
        shape: sekil,
        textStyle: yazi,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: dolgu,
        shape: sekil,
        foregroundColor: r.vurgu,
        side: BorderSide(color: r.vurgu, width: 1.5),
        textStyle: yazi,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(64, 48),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: r.sayfa,
        border: Border.all(color: r.cizgi),
        borderRadius: BorderRadius.circular(8),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: zemin ?? r.isaret, borderRadius: BorderRadius.circular(4)),
      child: Text(
        metin,
        style: TextStyle(
          fontSize: kucuk ? 12 : 13,
          fontWeight: FontWeight.w700,
          color: yazi ?? r.isaretUstu,
        ),
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
        child: Text(metin, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.3)),
      );
}

class SolukMetin extends StatelessWidget {
  const SolukMetin(this.metin, {super.key, this.boyut = 15});
  final String metin;
  final double boyut;

  @override
  Widget build(BuildContext context) =>
      Text(metin, style: TextStyle(fontSize: boyut, color: Renk.of(context).soluk, height: 1.4));
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: r.sayfa,
          border: Border.all(color: r.cizgi, width: 1.5),
          borderRadius: BorderRadius.circular(6),
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
