// LiD Koçu — görsel dil: prototipin sade "kitapçık" düzeni (kâğıt zemin, beyaz sayfa, mavi vurgu, sarı işaret). Açık ve koyu tema.
import 'package:flutter/material.dart';

class Pal {
  const Pal({
    required this.paper,
    required this.sheet,
    required this.ink,
    required this.muted,
    required this.line,
    required this.accent,
    required this.onAccent,
    required this.mark,
    required this.onMark,
    required this.good,
    required this.goodBg,
    required this.bad,
    required this.badBg,
  });

  final Color paper;
  final Color sheet;
  final Color ink;
  final Color muted;
  final Color line;
  final Color accent;
  final Color onAccent;
  final Color mark;
  final Color onMark;
  final Color good;
  final Color goodBg;
  final Color bad;
  final Color badBg;

  static const Pal light = Pal(
    paper: Color(0xFFF2F5F9),
    sheet: Color(0xFFFFFFFF),
    ink: Color(0xFF14233B),
    muted: Color(0xFF566479),
    line: Color(0xFFD3DBE6),
    accent: Color(0xFF1F4FD8),
    onAccent: Color(0xFFFFFFFF),
    mark: Color(0xFFFFC83D),
    onMark: Color(0xFF2A2100),
    good: Color(0xFF0D7A4F),
    goodBg: Color(0xFFDFF5EA),
    bad: Color(0xFFB3261E),
    badBg: Color(0xFFFDE7E5),
  );

  static const Pal dark = Pal(
    paper: Color(0xFF0F1726),
    sheet: Color(0xFF182235),
    ink: Color(0xFFE9EEF6),
    muted: Color(0xFFA3B0C4),
    line: Color(0xFF2E3B52),
    accent: Color(0xFF8FB0FF),
    onAccent: Color(0xFF0D1830),
    mark: Color(0xFFFFC83D),
    onMark: Color(0xFF2A2100),
    good: Color(0xFF5FD6A4),
    goodBg: Color(0xFF12382A),
    bad: Color(0xFFFF9D94),
    badBg: Color(0xFF47201D),
  );

  static Pal of(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? dark : light;
}

ThemeData buildTheme(Brightness brightness) {
  final Pal p = brightness == Brightness.dark ? Pal.dark : Pal.light;
  final ThemeData base = ThemeData(brightness: brightness, useMaterial3: true);
  final ColorScheme scheme = ColorScheme(
    brightness: brightness,
    primary: p.accent,
    onPrimary: p.onAccent,
    secondary: p.mark,
    onSecondary: p.onMark,
    error: p.bad,
    onError: p.sheet,
    surface: p.sheet,
    onSurface: p.ink,
  );
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: p.paper,
    dividerColor: p.line,
    textTheme: base.textTheme.apply(bodyColor: p.ink, displayColor: p.ink, fontSizeFactor: 1.08),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.sheet,
      indicatorColor: p.accent.withValues(alpha: 0.18),
      labelTextStyle: WidgetStatePropertyAll<TextStyle>(TextStyle(fontSize: 12, color: p.ink, fontWeight: FontWeight.w600)),
      iconTheme: WidgetStatePropertyAll<IconThemeData>(IconThemeData(color: p.ink)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        minimumSize: const Size.fromHeight(50),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        side: BorderSide(color: p.line),
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
