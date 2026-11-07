// Çalış sekmesi: tüm sorular veya yanlışlarım (Premium).
import 'package:flutter/material.dart';

import '../core/veri.dart';
import 'durum.dart';
import 'premium.dart';
import 'soru_karti.dart';
import 'tema.dart';

class CalisSayfasi extends StatefulWidget {
  const CalisSayfasi({super.key});

  @override
  State<CalisSayfasi> createState() => _CalisDurumu();
}

class _CalisDurumu extends State<CalisSayfasi> {
  String _filtre = 'all';
  List<Soru>? _liste; // filtre değişince çekilen görüntü; cevap verince yer değiştirmez
  int _idx = 0;
  int? _secim;

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    final kilit = _filtre == 'wrongs' && !s.premium;

    final filtre = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        SolukMetin(s.t('filter')),
        Acilir<String>(
          etiket: s.t('filter'),
          deger: _filtre,
          ogeler: [
            for (final k in const ['all', 'wrongs'])
              DropdownMenuItem<String>(value: k, child: Text(s.t(k))),
          ],
          degisti: (v) => setState(() {
            _filtre = v;
            _liste = null;
            _idx = 0;
            _secim = null;
          }),
        ),
      ],
    );

    Widget icerik;
    if (kilit) {
      icerik = const PremiumIcerik();
    } else {
      final l = _liste ??= (_filtre == 'wrongs' ? s.yanlislar : s.havuz);
      if (l.isEmpty) {
        icerik = Kart(child: Text(s.t('none')));
      } else {
        final i = _idx % l.length;
        final soru = l[i];
        icerik = Kart(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              SolukMetin(s.t('q', {'a': i + 1, 'b': l.length})),
              SoruKarti(
                key: ValueKey('calis-${soru.id}'),
                soru: soru,
                mod: KartModu.pratik,
                secim: _secim,
                onSec: (c) {
                  setState(() => _secim = c);
                  s.cevapla(soru, c);
                },
              ),
              if (_secim != null)
                FilledButton(
                  key: const ValueKey('sonraki-soru'),
                  onPressed: () {
                    s.sesDurdur();
                    setState(() {
                      _idx = (i + 1) % l.length;
                      _secim = null;
                    });
                    ustuneKaydir(context);
                  },
                  child: Text(s.t('next')),
                ),
            ],
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 18,
      children: [filtre, icerik],
    );
  }
}
