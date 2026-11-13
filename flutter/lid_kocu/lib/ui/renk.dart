// ÜRETİLDİ: tasarim/tokens.json -> tasarim/uret.py (python3 web/tools/derle.py). Elle değiştirme.
// Renk belirteçleri ("Klarheit" görsel kimliği). Metin/zemin çiftleri WCAG AA (4.5:1),
// şık çerçevesi ve vurgu çizgileri en az 3:1 sağlar.
import 'package:flutter/material.dart';

@immutable
class Renk {
  /// Paper: the scaffold background behind every screen, and the inset ground of picture descriptions inside a card. Also the text colour on filled yazi (selected language key, answered strip box).
  final Color kagit;
  /// Sheet: Kart, Acilir and option surfaces, dialogs and canvas. Also onError.
  final Color sayfa;
  /// Ink: all primary text on kagit, sayfa, dogruZemin and yanlisZemin (14.5:1 light, 15.4:1 dark on kagit). Also the fill of a selected language key and an answered strip box.
  final Color yazi;
  /// Muted text (SolukMetin): translations under the German line, hints, dates, footer, unanswered strip numbers. Reads 5.5:1 on kagit and 5.1:1 on yanlisZemin in light; 7.2:1 on sayfa in dark.
  final Color soluk;
  /// Hairline: Kart border (1px), tab-bar baseline (2px), unanswered strip box, progress track. Decorative only (1.4:1 on sayfa): never a control boundary, use secenekKenar there.
  final Color cizgi;
  /// Control boundary at rest (1.5px): answer options and the Acilir dropdown. 4.1:1 on sayfa light, 4.8:1 dark: clears 3:1.
  final Color secenekKenar;
  /// Accent (ColorScheme.primary): FilledButton fill, OutlinedButton and TextButton text and 1.5px border, selected option border (2.5px), active tab underline (3px), current strip box ring, progress fill, links, focus. As text, 8.4:1 on sayfa light, 7.0:1 dark.
  final Color vurgu;
  /// Text and icons on vurgu fills (onPrimary). White in light; deep navy in dark, because the dark accent is light.
  final Color vurguUstu;
  /// Marker yellow (secondary): Etiket chips, the 'Koçu' label in the wordmark, the 4px start rule beside an explanation. Same value in both themes. Never text on a light ground (1.4:1 on kagit).
  final Color isaret;
  /// Text on isaret (10.3:1).
  final Color isaretUstu;
  /// Correct: right-answer border and check_circle icon, 'Doğru.' feedback text, verified icons, correct strip boxes. 4.7:1 on dogruZemin light. dogru and yanlis differ by hue only (1.2:1), so pair them with an icon, a word, or a lightness difference (the result strip fills wrong boxes solid yanlis against light dogruZemin).
  final Color dogru;
  /// Tint behind a correct option or correct strip box.
  final Color dogruZemin;
  /// Wrong (ColorScheme.error): wrong-answer border and cancel icon, 'Yanlış.' feedback text, failed-result card border, and the solid fill of a wrong or blank box in the result strip (number in sayfa, 6.5:1 light, 8.0:1 dark). 5.5:1 on yanlisZemin light, 7.0:1 dark.
  final Color yanlis;
  /// Tint behind a wrong option, wrong strip box, or the result card after a failed mock test.
  final Color yanlisZemin;

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

  static Renk of(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? koyu : acik;
}
