// Soru kartı: Almanca soru, çeviri, görsel açıklamaları, şıklar, geri bildirim.
import 'package:flutter/material.dart';

import '../core/veri.dart';
import '../state.dart';
import 'durum.dart';
import 'premium.dart';
import 'tema.dart';

enum KartModu { pratik, sinav, inceleme }

class SoruKarti extends StatelessWidget {
  const SoruKarti({super.key, required this.soru, required this.mod, this.secim, this.onSec});

  final Soru soru;
  final KartModu mod;
  final int? secim;
  final ValueChanged<int>? onSec;

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    final r = Renk.of(context);
    final acik = mod == KartModu.inceleme || (mod == KartModu.pratik && secim != null);
    final etkin = mod == KartModu.sinav || (mod == KartModu.pratik && secim == null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        SoruBasligi(soru: soru),
        if (s.premium)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const ValueKey('dinle'),
              onPressed: () => s.dinle(soru),
              icon: const Icon(Icons.volume_up),
              label: Text(s.t('listen')),
            ),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            for (var i = 0; i < soru.secenekler.length; i++)
              _Secenek(
                key: ValueKey('secenek-$i'),
                soru: soru,
                indeks: i,
                durum: acik
                    ? (i == soru.dogru ? _Durum.dogru : (i == secim ? _Durum.yanlis : _Durum.yok))
                    : (secim == i ? _Durum.secili : _Durum.yok),
                etkin: etkin,
                onSec: onSec,
              ),
          ],
        ),
        if (mod == KartModu.pratik && secim != null)
          Semantics(
            liveRegion: true,
            child: Text(
              secim == soru.dogru ? s.t('right') : s.t('wrong'),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: secim == soru.dogru ? r.dogru : r.yanlis,
              ),
            ),
          ),
        if (mod == KartModu.inceleme && secim == null) SolukMetin(s.t('empty')),
        if (acik) AciklamaBolumu(soru: soru),
      ],
    );
  }
}

class SoruBasligi extends StatelessWidget {
  const SoruBasligi({super.key, required this.soru});
  final Soru soru;

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    final r = Renk.of(context);
    final c = s.ceviri(soru);
    final gDe = s.gorselDe(soru);
    final gCev = s.gorselCeviri(soru);
    final String? cs = (c != null && c.soru.isNotEmpty) ? c.soru : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Almanca(
          soru.de,
          key: const ValueKey('soru-de'),
          stil: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.35),
        ),
        if (cs != null)
          Text(cs, style: TextStyle(color: r.soluk, height: 1.4))
        else if (s.dil != 'de')
          SolukMetin(s.t('noTr')),
        if (gDe.isNotEmpty) SolukMetin(s.t('noImg')),
        if (gDe.length == 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: r.kagit, borderRadius: BorderRadius.circular(6)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                Almanca(gDe[0]),
                if (gCev.isNotEmpty) Text(gCev[0], style: TextStyle(color: r.soluk, fontSize: 15, height: 1.4)),
              ],
            ),
          ),
        if (soru.guncel)
          Align(alignment: AlignmentDirectional.centerStart, child: Etiket(s.t('dated'))),
      ],
    );
  }
}

enum _Durum { yok, secili, dogru, yanlis }

class _Secenek extends StatelessWidget {
  const _Secenek({
    super.key,
    required this.soru,
    required this.indeks,
    required this.durum,
    required this.etkin,
    required this.onSec,
  });

  final Soru soru;
  final int indeks;
  final _Durum durum;
  final bool etkin;
  final ValueChanged<int>? onSec;

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    final r = Renk.of(context);
    final c = s.ceviri(soru);
    final gDe = s.gorselDe(soru);
    final gCev = s.gorselCeviri(soru);
    final i = indeks;
    final kucuk = TextStyle(color: r.soluk, fontSize: 15, height: 1.4);

    final (Color kenar, Color zemin, double kalinlik) = switch (durum) {
      _Durum.dogru => (r.dogru, r.dogruZemin, 1.5),
      _Durum.yanlis => (r.yanlis, r.yanlisZemin, 1.5),
      _Durum.secili => (r.vurgu, Colors.transparent, 2.5),
      _Durum.yok => (r.cizgi, Colors.transparent, 1.5),
    };

    return Semantics(
      button: true,
      enabled: etkin,
      selected: durum == _Durum.secili,
      hint: durum == _Durum.dogru ? s.t('right') : null,
      child: Material(
        color: zemin,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: kenar, width: kalinlik),
          borderRadius: BorderRadius.circular(6),
        ),
        child: InkWell(
          onTap: etkin && onSec != null ? () => onSec!(i) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 2,
                      children: [
                        Almanca(soru.secenekler[i], stil: const TextStyle(fontSize: 17, height: 1.4)),
                        if (c != null && i < c.secenekler.length) Text(c.secenekler[i], style: kucuk),
                        if (gDe.length == 4) Almanca(gDe[i], stil: kucuk),
                        if (gCev.length == 4) Text(gCev[i], style: kucuk),
                      ],
                    ),
                  ),
                  if (durum == _Durum.dogru || durum == _Durum.yanlis) ...[
                    const SizedBox(width: 8),
                    ExcludeSemantics(
                      child: Icon(
                        durum == _Durum.dogru ? Icons.check_circle : Icons.cancel,
                        color: durum == _Durum.dogru ? r.dogru : r.yanlis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Açıklama: Premium veya örnek ise metin, değilse kilit notu ve Premium düğmesi.
class AciklamaBolumu extends StatelessWidget {
  const AciklamaBolumu({super.key, required this.soru});
  final Soru soru;

  @override
  Widget build(BuildContext context) {
    final AppState s = DurumKapsami.of(context);
    final r = Renk.of(context);
    if (!s.aciklamaAcik(soru)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          SolukMetin(s.t('locked')),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton(
              key: const ValueKey('premium-ac'),
              onPressed: () => premiumAc(context),
              child: Text(s.t('open')),
            ),
          ),
        ],
      );
    }
    final a = s.aciklama(soru);
    if (a == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsetsDirectional.only(start: 10),
      decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: r.isaret, width: 4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          if (!s.premium && ornekAciklama(soru.id))
            Align(alignment: AlignmentDirectional.centerStart, child: Etiket(s.t('sample'), kucuk: true)),
          Text(a, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}
