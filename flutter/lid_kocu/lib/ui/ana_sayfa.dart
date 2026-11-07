// Ana sayfa: karşılama, eyalet seçimi, ilerleme, günün sorusu, sınav girişi.
import 'package:flutter/material.dart';

import '../core/veri.dart';
import 'durum.dart';
import 'premium.dart';
import 'soru_karti.dart';
import 'tema.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key, required this.onSinavBasla});
  final VoidCallback onSinavBasla;

  @override
  State<AnaSayfa> createState() => _AnaSayfaDurumu();
}

class _AnaSayfaDurumu extends State<AnaSayfa> {
  int? _secim;

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    final r = Renk.of(context);
    final havuz = s.havuz;
    final dogru = s.dogruSayisi;
    final Soru gun = s.gununSorusu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 18,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Semantics(
              header: true,
              child: Text(
                s.t('hero'),
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.15),
              ),
            ),
            Text(s.t('sub')),
          ],
        ),
        Kart(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Baslik(s.t('state')),
              Acilir<String>(
                etiket: s.t('state'),
                deger: s.eyalet,
                ogeler: [
                  for (final e in s.katalog.eyaletler.entries)
                    DropdownMenuItem<String>(value: e.key, child: Text(e.value.ad)),
                ],
                degisti: s.eyaletSec,
              ),
              ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: havuz.isEmpty ? 0 : dogru / havuz.length,
                    minHeight: 10,
                    backgroundColor: r.cizgi,
                    color: r.vurgu,
                  ),
                ),
              ),
              SolukMetin(s.t('learned', {'a': dogru, 'b': havuz.length})),
            ],
          ),
        ),
        Kart(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Baslik(s.t('today')),
              SoruKarti(
                key: ValueKey('gun-${gun.id}'),
                soru: gun,
                mod: KartModu.pratik,
                secim: _secim,
                onSec: (i) {
                  setState(() => _secim = i);
                  s.cevapla(gun, i);
                },
              ),
            ],
          ),
        ),
        Kart(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(s.t('examInfo')),
              FilledButton(
                key: const ValueKey('basla-ana'),
                onPressed: widget.onSinavBasla,
                child: Text(s.t('startExam')),
              ),
            ],
          ),
        ),
        Kart(
          child: s.premium
              ? Row(
                  children: [
                    ExcludeSemantics(child: Icon(Icons.verified, color: r.dogru)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.t('owned'), style: TextStyle(fontWeight: FontWeight.w700, color: r.dogru)),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    Baslik(s.t('premiumTitle')),
                    Text(s.t('premiumSub')),
                    OutlinedButton(
                      key: const ValueKey('premium-ana'),
                      onPressed: () => premiumAc(context),
                      child: Text(s.t('open')),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
