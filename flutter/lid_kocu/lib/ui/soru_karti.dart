// Soru kartı: Almanca soru, çeviri, görsel açıklamaları, şıklar, geri bildirim.
import 'package:flutter/material.dart';

import '../core/veri.dart';
import '../state.dart';
import 'durum.dart';
import 'premium.dart';
import 'tema.dart';

enum KartModu { pratik, sinav, inceleme }

class SoruKarti extends StatelessWidget {
  const SoruKarti({
    super.key,
    required this.soru,
    required this.mod,
    this.secim,
    this.onSec,
    this.ucretsizAciklama = false,
  });

  final Soru soru;
  final KartModu mod;
  final int? secim;
  final ValueChanged<int>? onSec;

  /// Premium olmadan da açıklama açık (günün sorusu, yanlış listesinin ilk 3'ü).
  final bool ucretsizAciklama;

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
        Align(alignment: AlignmentDirectional.centerStart, child: DinleDugmesi(soru: soru)),
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
        if (acik) AciklamaBolumu(soru: soru, ucretsiz: ucretsizAciklama),
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
      _Durum.yok => (r.secenekKenar, Colors.transparent, 1.5),
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

/// Sesli dinleme. Premium'da Almanca soruyu okur; ücretsiz kullanıcıda kilitli görünür ve Premium ekranını açar.
/// Kart kapanınca (soru değişince, sekme değişince) ses durur.
class DinleDugmesi extends StatefulWidget {
  const DinleDugmesi({super.key, required this.soru});
  final Soru soru;

  @override
  State<DinleDugmesi> createState() => _DinleDugmesiDurumu();
}

class _DinleDugmesiDurumu extends State<DinleDugmesi> {
  AppState? _s;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _s = DurumKapsami.oku(context);
  }

  @override
  void didUpdateWidget(DinleDugmesi eski) {
    super.didUpdateWidget(eski);
    if (eski.soru.id != widget.soru.id) _s?.sesDurdur();
  }

  @override
  void dispose() {
    _s?.sesDurdur();
    super.dispose();
  }

  Future<void> _cal() async {
    final s = DurumKapsami.oku(context);
    final m = ScaffoldMessenger.of(context);
    final r = await s.dinle(widget.soru);
    if (!mounted) return;
    switch (r) {
      case SesSonucu.tamam:
        break;
      case SesSonucu.kilitli:
        premiumAc(context);
      case SesSonucu.dilYok:
        await showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            key: const ValueKey('tts-yok'),
            title: Text(s.t('ttsMissingTitle')),
            content: Text(s.t('ttsMissing')),
            actions: [
              TextButton(onPressed: () => Navigator.of(c).pop(), child: Text(s.t('ok'))),
            ],
          ),
        );
      case SesSonucu.hata:
        m.showSnackBar(SnackBar(content: Text(s.t('ttsError'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    return TextButton.icon(
      key: const ValueKey('dinle'),
      onPressed: s.premium ? _cal : () => premiumAc(context),
      icon: Icon(s.premium ? Icons.volume_up : Icons.lock),
      label: Text(s.premium ? s.t('listen') : s.t('listenPremium')),
    );
  }
}

/// Açıklama: Premium veya ücretsiz ise metin, değilse kilit notu ve fiyatlı Premium düğmesi.
class AciklamaBolumu extends StatelessWidget {
  const AciklamaBolumu({super.key, required this.soru, this.ucretsiz = false});
  final Soru soru;
  final bool ucretsiz;

  @override
  Widget build(BuildContext context) {
    final AppState s = DurumKapsami.of(context);
    final r = Renk.of(context);
    if (!s.aciklamaAcik(soru, ucretsiz: ucretsiz)) {
      final fiyat = s.billing.fiyat;
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
              child: Text(fiyat != null ? s.t('buyShort', {'p': fiyat}) : s.t('open')),
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
          if (!s.premium)
            Align(alignment: AlignmentDirectional.centerStart, child: Etiket(s.t('sample'), kucuk: true)),
          Text(a, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}
