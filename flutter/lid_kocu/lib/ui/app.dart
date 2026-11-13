// Uygulama kabuğu: MaterialApp, dil/tema, ilk açılış, üst bilgi, sekmeler, alt bilgi.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../state.dart';
import 'alt_bilgi.dart';
import 'ana_sayfa.dart';
import 'calis.dart';
import 'durum.dart';
import 'ilk_acilis.dart';
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
  late final AppLifecycleListener _yasam;
  Timer? _sure;

  @override
  void initState() {
    super.initState();
    _yasam = AppLifecycleListener(
      onResume: () => DurumKapsami.oku(context).onPlanaDondu(),
      onHide: () => DurumKapsami.oku(context).sesDurdur(),
    );
    // Sınav süresi hangi sekmede olunursa olsun dolunca sınav biter.
    _sure = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) DurumKapsami.oku(context).sureKontrol();
    });
  }

  @override
  void dispose() {
    _sure?.cancel();
    _yasam.dispose();
    _kaydirma.dispose();
    super.dispose();
  }

  void _ustTarafa() {
    if (_kaydirma.hasClients) _kaydirma.jumpTo(0);
  }

  void _sekmeSec(int i) {
    DurumKapsami.oku(context).sesDurdur();
    setState(() {
      _sekme = i;
      _limit = false;
    });
    _ustTarafa();
  }

  /// Devam eden sınav varsa ona döner; yoksa (hak varsa) yeni sınav açar.
  void _sinavBasla() {
    final ok = DurumKapsami.oku(context).sinavBaslat();
    setState(() {
      _limit = !ok;
      _sekme = 2;
    });
    _ustTarafa();
  }

  void _yanlisCalis() {
    DurumKapsami.oku(context).sonSinavYanlisCalis();
    setState(() {
      _sekme = 1;
      _limit = false;
    });
    _ustTarafa();
  }

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    if (!s.kurulumTamam) {
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(Bosluk.b16, Bosluk.b24, Bosluk.b16, Bosluk.b40),
                  child: IlkAcilis(),
                ),
              ),
            ),
          ),
        ),
      );
    }
    final Widget govde = switch (_sekme) {
      0 => AnaSayfa(onSinavBasla: _sinavBasla),
      1 => const CalisSayfasi(),
      _ => SinavSayfasi(limit: _limit, onBasla: _sinavBasla, onYanlisCalis: _yanlisCalis),
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
                  padding: const EdgeInsets.fromLTRB(Bosluk.b16, Bosluk.b16, Bosluk.b16, Bosluk.b40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: Bosluk.b18,
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

  static const _kisa = {'tr': 'TR', 'en': 'EN', 'de': 'DE', 'ar': 'عر'};

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    final r = Renk.of(context);
    return Wrap(
      spacing: Bosluk.b10,
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
                const Text('LiD', style: Yazi.marka),
                const SizedBox(width: Bosluk.b6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Bosluk.b6),
                  decoration: BoxDecoration(color: r.isaret, borderRadius: BorderRadius.circular(Kose.etiket)),
                  child: Text(
                    'Koçu',
                    style: Yazi.marka.copyWith(height: 1.1, color: r.isaretUstu),
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: Bosluk.b4,
          children: [
            for (final d in diller)
              Semantics(
                button: true,
                selected: s.dil == d,
                label: dilAdlari[d],
                excludeSemantics: true,
                onTap: () => s.dilSec(d),
                child: InkWell(
                  key: ValueKey('dil-$d'),
                  borderRadius: BorderRadius.circular(Kose.kart),
                  onTap: () => s.dilSec(d),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Padding(
                      padding: const EdgeInsets.all(Bosluk.b3),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: s.dil == d ? r.yazi : Colors.transparent,
                          border: Border.all(color: s.dil == d ? r.yazi : r.cizgi),
                          borderRadius: BorderRadius.circular(Kose.kontrol),
                        ),
                        child: Center(
                          child: Text(
                            _kisa[d]!,
                            style: Yazi.dilKisa.copyWith(color: s.dil == d ? r.kagit : r.yazi),
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
                onTap: () => secildi(i),
                child: InkWell(
                  key: ValueKey(_kimlik[i]),
                  onTap: () => secildi(i),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: Olcu.dokunma),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: Bosluk.b4, vertical: Bosluk.b10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: i == secili ? r.vurgu : Colors.transparent, width: 3),
                      ),
                    ),
                    child: Text(
                      state.t(_anahtarlar[i]),
                      textAlign: TextAlign.center,
                      style: Yazi.dugme.copyWith(color: i == secili ? r.yazi : r.soluk),
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
