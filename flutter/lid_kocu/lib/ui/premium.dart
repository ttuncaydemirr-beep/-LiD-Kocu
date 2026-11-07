// Premium ekranı: tek seferlik satın alma. Hem sayfa hem satır içi kullanılır.
import 'package:flutter/material.dart';

import '../services/billing.dart';
import 'durum.dart';
import 'tema.dart';

void premiumAc(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PremiumSayfasi()));
}

class PremiumSayfasi extends StatelessWidget {
  const PremiumSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    final r = Renk.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('premium')),
        backgroundColor: r.kagit,
        foregroundColor: r.yazi,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: PremiumIcerik(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumIcerik extends StatefulWidget {
  const PremiumIcerik({super.key});

  @override
  State<PremiumIcerik> createState() => _PremiumIcerikState();
}

class _PremiumIcerikState extends State<PremiumIcerik> {
  bool _mesgul = false;

  Future<void> _satinAl() async {
    final s = DurumKapsami.oku(context);
    final m = ScaffoldMessenger.of(context);
    setState(() => _mesgul = true);
    SatinAlmaSonucu r;
    try {
      r = await s.satinAl();
    } catch (_) {
      r = SatinAlmaSonucu.hata;
    }
    if (mounted) setState(() => _mesgul = false);
    final String? anahtar = switch (r) {
      SatinAlmaSonucu.alindi => 'owned',
      SatinAlmaSonucu.bekliyor => 'pending',
      SatinAlmaSonucu.iptal => null,
      SatinAlmaSonucu.hata => 'failed2',
      SatinAlmaSonucu.yok => 'unavail',
    };
    if (anahtar != null) m.showSnackBar(SnackBar(content: Text(s.t(anahtar))));
  }

  Future<void> _geriYukle() async {
    final s = DurumKapsami.oku(context);
    final m = ScaffoldMessenger.of(context);
    setState(() => _mesgul = true);
    bool? r;
    try {
      r = await s.geriYukle();
    } catch (_) {
      r = null;
    }
    if (mounted) setState(() => _mesgul = false);
    final anahtar = r == true ? 'owned' : (r == false ? 'noPurchase' : 'failed2');
    m.showSnackBar(SnackBar(content: Text(s.t(anahtar))));
  }

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    final r = Renk.of(context);
    final fiyat = s.billing.fiyat;
    return Kart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Semantics(
            header: true,
            child: Text(
              s.t('premiumTitle'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.2),
            ),
          ),
          Text(s.t('premiumSub'), style: const TextStyle(height: 1.5)),
          for (final k in const ['pf1', 'pf2', 'pf3', 'pf4'])
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: Icon(Icons.check_circle, color: r.dogru, size: 22)),
                const SizedBox(width: 10),
                Expanded(child: Text(s.t(k), style: const TextStyle(height: 1.4))),
              ],
            ),
          if (s.premium)
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  ExcludeSemantics(child: Icon(Icons.verified, color: r.dogru)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.t('owned'), style: TextStyle(fontWeight: FontWeight.w700, color: r.dogru)),
                  ),
                ],
              ),
            )
          else ...[
            FilledButton(
              key: const ValueKey('satin-al'),
              onPressed: _mesgul ? null : _satinAl,
              child: Text(fiyat != null ? s.t('buy', {'p': fiyat}) : s.t('buyNoPrice')),
            ),
            TextButton(
              key: const ValueKey('geri-yukle'),
              onPressed: _mesgul ? null : _geriYukle,
              child: Text(s.t('restore')),
            ),
          ],
        ],
      ),
    );
  }
}
