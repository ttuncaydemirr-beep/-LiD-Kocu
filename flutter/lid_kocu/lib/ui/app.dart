// Uygulama kabuğu: MaterialApp, dil/tema, üst bilgi, sekmeler, alt bilgi.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../state.dart';
import 'alt_bilgi.dart';
import 'ana_sayfa.dart';
import 'calis.dart';
import 'durum.dart';
import 'sinav.dart';
import 'tema.dart';

class LidKocuApp extends StatelessWidget {
  const LidKocuApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => DurumKapsami(state: state, child: const _Kok());
}

class _Kok extends StatelessWidget {
  const _Kok();

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    return MaterialApp(
      title: 'LiD Koçu',
      debugShowCheckedModeBanner: false,
      locale: Locale(s.dil),
      supportedLocales: [for (final d in diller) Locale(d)],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: temaOlustur(Brightness.light),
      darkTheme: temaOlustur(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const Kabuk(),
    );
  }
}

class Kabuk extends StatefulWidget {
  const Kabuk({super.key});

  @override
  State<Kabuk> createState() => _KabukDurumu();
}

class _KabukDurumu extends State<Kabuk> {
  int _sekme = 0;
  bool _limit = false;
  final ScrollController _kaydirma = ScrollController();

  @override
  void dispose() {
    _kaydirma.dispose();
    super.dispose();
  }

  void _sekmeSec(int i) {
    setState(() {
      _sekme = i;
      _limit = false;
    });
    if (_kaydirma.hasClients) _kaydirma.jumpTo(0);
  }

  void _sinavBasla() {
    final ok = DurumKapsami.oku(context).sinavBaslat();
    setState(() {
      _limit = !ok;
      _sekme = 2;
    });
    if (_kaydirma.hasClients) _kaydirma.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    final Widget govde = switch (_sekme) {
      0 => AnaSayfa(onSinavBasla: _sinavBasla),
      1 => const CalisSayfasi(),
      _ => SinavSayfasi(limit: _limit, onBasla: _sinavBasla),
    };
    return Scaffold(
      body: SafeArea(
        child: KaydirmaKapsami(
          denetleyici: _kaydirma,
          child: SingleChildScrollView(
            controller: _kaydirma,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 18,
                    children: [
                      const _Ust(),
                      _Sekmeler(secili: _sekme, secildi: _sekmeSec, state: s),
                      KeyedSubtree(key: ValueKey('sekme-icerik-$_sekme'), child: govde),
                      const AltBilgi(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Ust extends StatelessWidget {
  const _Ust();

  static const _adlar = {'tr': 'Türkçe', 'en': 'English', 'de': 'Deutsch', 'ar': 'العربية'};
  static const _kisa = {'tr': 'TR', 'en': 'EN', 'de': 'DE', 'ar': 'عر'};

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    final r = Renk.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Semantics(
            header: true,
            label: 'LiD Koçu',
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('LiD', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(color: r.isaret, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    'Koçu',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.1, color: r.isaretUstu),
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            for (final d in diller)
              Semantics(
                button: true,
                selected: s.dil == d,
                label: _adlar[d],
                excludeSemantics: true,
                child: InkWell(
                  key: ValueKey('dil-$d'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => s.dilSec(d),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: s.dil == d ? r.yazi : Colors.transparent,
                          border: Border.all(color: s.dil == d ? r.yazi : r.cizgi),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            _kisa[d]!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: s.dil == d ? r.kagit : r.yazi,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Sekmeler extends StatelessWidget {
  const _Sekmeler({required this.secili, required this.secildi, required this.state});
  final int secili;
  final ValueChanged<int> secildi;
  final AppState state;

  static const _anahtarlar = ['home', 'study', 'exam'];
  static const _kimlik = ['sekme-ana', 'sekme-calis', 'sekme-sinav'];

  @override
  Widget build(BuildContext context) {
    final r = Renk.of(context);
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: r.cizgi, width: 2))),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == secili,
                excludeSemantics: true,
                label: state.t(_anahtarlar[i]),
                child: InkWell(
                  key: ValueKey(_kimlik[i]),
                  onTap: () => secildi(i),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: i == secili ? r.vurgu : Colors.transparent, width: 3),
                      ),
                    ),
                    child: Text(
                      state.t(_anahtarlar[i]),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: i == secili ? r.yazi : r.soluk,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
