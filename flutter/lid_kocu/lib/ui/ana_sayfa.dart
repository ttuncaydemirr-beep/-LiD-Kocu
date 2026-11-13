// Ana sayfa: karşılama, eyalet seçimi, hazırlık göstergesi, günün sorusu, sınav girişi.
import 'package:flutter/material.dart';

import '../core/veri.dart';
import '../state.dart';
import 'durum.dart';
import 'premium.dart';
import 'reklam_alani.dart';
import 'soru_karti.dart';
import 'tema.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key, required this.onSinavBasla});
  final VoidCallback onSinavBasla;

  @override
  State<AnaSayfa> createState() => _AnaSayfaDurumu();
}

String _tarih(DateTime t) =>
    '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';

class _AnaSayfaDurumu extends State<AnaSayfa> {
  // Seçim, günün sorusunun kimliğine bağlı: gece yarısı geçince eski seçim yeni soruya taşınmaz.
  int? _secim;
  String? _secimId;

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    final r = Renk.of(context);
    final havuz = s.havuz;
    final dogru = s.dogruSayisi;
    final Soru gun = s.gununSorusu;
    final ort = s.son3Ortalama;
    final kalan = s.ucretsizKalanSinav;
    final devam = s.sinavDevamEdiyor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Bosluk.b18,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Bosluk.b12,
          children: [
            Semantics(
              header: true,
              child: Text(
                s.t('hero'),
                style: Yazi.hero,
              ),
            ),
            Text(s.t('sub')),
          ],
        ),
        Kart(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Bosluk.b12,
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
                  borderRadius: BorderRadius.circular(Kose.cubuk),
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
          key: const ValueKey('hazirlik'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Bosluk.b8,
            children: [
              Baslik(s.t('ready', {'n': s.hazirlik})),
              if (ort != null)
                Text(s.t('avg3', {'a': ort.toStringAsFixed(1), 'b': sinavSoruSayisi}))
              else
                SolukMetin(s.t('noHistory')),
              for (final k in s.gecmis.reversed.take(3))
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Align(
                    alignment: s.rtl ? Alignment.centerRight : Alignment.centerLeft,
                    child: SolukMetin('${_tarih(k.tarih)}  ·  ${k.puan} / $sinavSoruSayisi'),
                  ),
                ),
            ],
          ),
        ),
        Kart(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Bosluk.b12,
            children: [
              Baslik(s.t('today')),
              SoruKarti(
                key: ValueKey('gun-${gun.id}'),
                soru: gun,
                mod: KartModu.pratik,
                secim: _secimId == gun.id ? _secim : null,
                ucretsizAciklama: true,
                onSec: (i) {
                  setState(() {
                    _secim = i;
                    _secimId = gun.id;
                  });
                  s.cevapla(gun, i);
                },
              ),
            ],
          ),
        ),
        Kart(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Bosluk.b12,
            children: [
              Text(s.t('examInfo')),
              if (kalan != null && !devam) SolukMetin(ucretsizMetni(s, kalan)),
              FilledButton(
                key: const ValueKey('basla-ana'),
                onPressed: widget.onSinavBasla,
                child: Text(s.t(devam ? 'continueExam' : 'startExam')),
              ),
            ],
          ),
        ),
        Kart(
          child: s.premium
              ? Row(
                  children: [
                    ExcludeSemantics(child: Icon(Icons.verified, color: r.dogru)),
                    const SizedBox(width: Bosluk.b10),
                    Expanded(
                      child: Text(s.t('owned'), style: TextStyle(fontWeight: FontWeight.w700, color: r.dogru)),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: Bosluk.b12,
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
        // Tek banner: Premium kartının altında, yalnızca ücretsiz (ve kontrol grubunda olmayan) kullanıcıya.
        if (!s.premium && s.reklam.bannerAlani) const ReklamBanner(),
      ],
    );
  }
}

/// Kalan ücretsiz deneme bilgisi.
String ucretsizMetni(AppState s, int kalan) {
  final ek = s.ekHakKalan;
  if (kalan <= 0) return ek > 0 ? s.t('bonusLeft', {'n': ek}) : s.t('freeNone');
  if (s.sinavSayisi >= ucretsizSinav) return s.t('freeToday');
  return s.t('freeLeft', {'n': kalan});
}
