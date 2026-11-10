// Çalış sekmesi: tüm sorular, yanlışlarım, son denemenin yanlışları. Kaldığı yerden devam eder (süzgeç başına),
// isteğe bağlı karışık sıra. Yanlış listelerinde Premium olmadan ilk 3 sorunun açıklaması açıktır.
import 'package:flutter/material.dart';

import '../core/veri.dart';
import '../state.dart';
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
  List<Soru>? _liste; // süzgeç değişince çekilen görüntü; cevap verince yer değiştirmez
  String? _listeFiltre;
  int _idx = 0;
  int? _secim;

  void _sifirla() {
    _liste = null;
    _listeFiltre = null;
    _secim = null;
  }

  void _git(AppState s, String f, List<Soru> l, int i) {
    s.sesDurdur();
    setState(() {
      _idx = i;
      _secim = null;
    });
    if (l.isNotEmpty) s.calisKonumKaydet(f, l[i].id);
    ustuneKaydir(context);
  }

  /// Listedeki ilk ücretsiz (açık) sorunun sırası; yoksa 0.
  int _ilkAcik(AppState s, List<Soru> l) {
    final k = l.indexWhere(s.yanlisUcretsiz);
    return k < 0 ? 0 : k;
  }

  /// Sonraki soru. Premium'suz yanlış listelerinde kilitli soruları atlar: ileride açık soru varsa ona,
  /// yoksa (ve ardında kilitli soru varsa) bir kez kilit kartına, değilse baştaki açık soruya gider.
  int _sonraki(AppState s, bool yanlisListesi, List<Soru> l, int i) {
    if (!yanlisListesi || s.premium) return (i + 1) % l.length;
    for (var k = i + 1; k < l.length; k++) {
      if (s.yanlisUcretsiz(l[k])) return k;
    }
    return i + 1 < l.length ? i + 1 : _ilkAcik(s, l);
  }

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    final f = s.calisFiltre;
    final yanlisListesi = f == filtreYanlis || f == filtreSinav;

    if (_listeFiltre != f || _liste == null) {
      final l = s.calismaListesi(f);
      _liste = l;
      _listeFiltre = f;
      _idx = s.calisBaslangic(f, l);
      _secim = null;
    }
    final l = _liste!;

    final ust = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        SolukMetin(s.t('filter')),
        Acilir<String>(
          etiket: s.t('filter'),
          deger: f,
          ogeler: [
            for (final k in [filtreTumu, filtreYanlis, if (s.sonSinavYanlislari != null) filtreSinav])
              DropdownMenuItem<String>(value: k, child: Text(s.t(k == filtreSinav ? 'examWrongs' : k))),
          ],
          degisti: (v) {
            setState(_sifirla);
            s.calisFiltreSec(v);
          },
        ),
        if (f != filtreSinav)
          MergeSemantics(
            child: SwitchListTile(
              key: const ValueKey('karisik'),
              contentPadding: EdgeInsets.zero,
              title: Text(s.t('shuffle')),
              value: s.karisik,
              onChanged: (v) {
                setState(_sifirla);
                s.karisikSec(v);
              },
            ),
          ),
        if (yanlisListesi) ...[
          Text(s.t('wrongsCount', {'n': l.length}), key: const ValueKey('yanlis-sayisi')),
          if (!s.premium && l.isNotEmpty) SolukMetin(s.t('firstFree', {'n': ucretsizYanlis})),
        ],
      ],
    );

    Widget icerik;
    if (l.isEmpty) {
      icerik = Kart(child: Text(s.t('none')));
    } else {
      final i = _idx % l.length;
      final soru = l[i];
      if (yanlisListesi && !s.premium && !s.yanlisUcretsiz(soru)) {
        // Kilit kimliğe bağlıdır (listedeki konuma değil): sıra değişse de açılan sorular sabit kalır.
        icerik = _KilitKarti(
          kalan: l.where((q) => !s.yanlisUcretsiz(q)).length,
          onBastan: () => _git(s, f, l, _ilkAcik(s, l)),
        );
      } else {
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
                ucretsizAciklama: yanlisListesi,
                onSec: (c) {
                  setState(() => _secim = c);
                  s.cevapla(soru, c);
                },
              ),
              if (_secim != null)
                FilledButton(
                  key: const ValueKey('sonraki-soru'),
                  onPressed: () => _git(s, f, l, _sonraki(s, yanlisListesi, l, i)),
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
      children: [ust, icerik],
    );
  }
}

/// Yanlış listesinde ücretsiz 3 sorudan sonra: kişisel Premium teklifi.
class _KilitKarti extends StatelessWidget {
  const _KilitKarti({required this.kalan, required this.onBastan});
  final int kalan;
  final VoidCallback onBastan;

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    final fiyat = s.billing.fiyat;
    return Kart(
      key: const ValueKey('yanlis-kilit'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            children: [
              const ExcludeSemantics(child: Icon(Icons.lock)),
              const SizedBox(width: 10),
              Expanded(child: Baslik(s.t('lockedRest', {'n': kalan}))),
            ],
          ),
          Text(s.t('premiumSub')),
          FilledButton(
            key: const ValueKey('yanlis-premium'),
            onPressed: () => premiumAc(context),
            child: Text(fiyat != null ? s.t('buyShort', {'p': fiyat}) : s.t('open')),
          ),
          OutlinedButton(key: const ValueKey('bastan'), onPressed: onBastan, child: Text(s.t('restart'))),
        ],
      ),
    );
  }
}
