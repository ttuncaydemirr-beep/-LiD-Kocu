// Deneme sınavı: giriş, sınav sırası (sayaç, numara şeridi), sonuç ve inceleme.
import 'dart:async';

import 'package:flutter/material.dart';

import '../core/veri.dart';
import '../services/reklam_karar.dart' show gecisGecikmesi, gecisGosterilebilir;
import '../state.dart';
import 'ana_sayfa.dart' show ucretsizMetni;
import 'durum.dart';
import 'premium.dart';
import 'reklam_alani.dart';
import 'soru_karti.dart';
import 'tema.dart';

class SinavSayfasi extends StatelessWidget {
  const SinavSayfasi({super.key, required this.limit, required this.onBasla, required this.onYanlisCalis});

  /// Hak bittiği için sınav başlatılamadı.
  final bool limit;
  final VoidCallback onBasla;

  /// Sonuç ekranından "Yanlışlarını çalış".
  final VoidCallback onYanlisCalis;

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    final x = s.sinav;
    if (limit && !s.premium && (x == null || x.bitti)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 18,
        children: [
          Semantics(
            liveRegion: true,
            child: Kart(key: const ValueKey('sinav-limit'), child: Text(s.t('freeNone'))),
          ),
          // "Reklam izle, 1 deneme daha aç" (yalnızca ücretsiz kullanıcı; Premium alanının yanında).
          OdulluTeklif(onBasla: onBasla),
          const PremiumIcerik(),
        ],
      );
    }
    if (x == null) {
      final kalan = s.ucretsizKalanSinav;
      return Kart(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Baslik(s.t('exam')),
            Text(s.t('examInfo')),
            if (kalan != null) SolukMetin(ucretsizMetni(s, kalan)),
            FilledButton(key: const ValueKey('basla'), onPressed: onBasla, child: Text(s.t('startExam'))),
          ],
        ),
      );
    }
    if (x.bitti) return _Sonuc(sinav: x, onBasla: onBasla, onYanlisCalis: onYanlisCalis);
    return _Devam(sinav: x);
  }
}

String _saat(Duration d) {
  final sn = d.inSeconds < 0 ? 0 : d.inSeconds;
  return '${(sn ~/ 60).toString().padLeft(2, '0')}:${(sn % 60).toString().padLeft(2, '0')}';
}

/// Saniyelik geri sayım; süre dolunca sınavı bitirir. (Sekme kapalıyken de Kabuk zamanlayıcısı
/// ve AppState.sinav erişimi süreyi denetler.)
class SinavSayaci extends StatefulWidget {
  const SinavSayaci({super.key, required this.state});
  final AppState state;

  @override
  State<SinavSayaci> createState() => _SinavSayaciDurumu();
}

class _SinavSayaciDurumu extends State<SinavSayaci> {
  Timer? _zamanlayici;
  late Duration _kalan;

  Duration _hesapla() {
    final x = widget.state.sinav;
    if (x == null || x.bitti) return Duration.zero;
    final ms = x.bitis.difference(widget.state.simdi()).inMilliseconds;
    if (ms <= 0) return Duration.zero;
    return Duration(seconds: (ms + 999) ~/ 1000);
  }

  @override
  void initState() {
    super.initState();
    _kalan = _hesapla();
    _zamanlayici = Timer.periodic(const Duration(seconds: 1), (_) => _tik());
  }

  void _tik() {
    if (!mounted) return;
    final k = _hesapla();
    if (k <= Duration.zero) {
      _zamanlayici?.cancel();
      _zamanlayici = null;
      widget.state.sureKontrol();
      return;
    }
    setState(() => _kalan = k);
  }

  @override
  void dispose() {
    _zamanlayici?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          _saat(_kalan),
          key: const ValueKey('sayac'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      );
}

class _Devam extends StatelessWidget {
  const _Devam({required this.sinav});
  final Sinav sinav;

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    final x = sinav;
    final n = x.sorular.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: SolukMetin(s.t('q', {'a': x.sira + 1, 'b': n}))),
            SinavSayaci(state: s),
          ],
        ),
        NumaraSeridi(sinav: x),
        Kart(
          child: SoruKarti(
            soru: x.sorular[x.sira],
            mod: KartModu.sinav,
            secim: x.cevaplar[x.sira],
            onSec: (i) {
              s.sinavCevap(i);
              ustuneKaydir(context);
            },
          ),
        ),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('onceki'),
                onPressed: x.sira > 0
                    ? () {
                        s.sinavGit(x.sira - 1);
                        ustuneKaydir(context);
                      }
                    : null,
                child: Text(s.t('prev')),
              ),
            ),
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('sonraki'),
                onPressed: x.sira < n - 1
                    ? () {
                        s.sinavGit(x.sira + 1);
                        ustuneKaydir(context);
                      }
                    : null,
                child: Text(s.t('nextQ')),
              ),
            ),
          ],
        ),
        FilledButton(
          key: const ValueKey('bitir'),
          onPressed: () => _bitir(context, s, x),
          child: Text(s.t('finish')),
        ),
        if (x.bos > 0) SolukMetin(s.t('left', {'n': x.bos})),
      ],
    );
  }
}

/// Boş soru varsa onay ister, sonra sınavı bitirir.
Future<void> _bitir(BuildContext context, AppState s, Sinav x) async {
  if (x.bos > 0) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        key: const ValueKey('bitir-dialog'),
        title: Text(s.t('confirmFinishTitle')),
        content: Text(s.t('confirmFinishBody', {'n': x.bos})),
        actions: [
          TextButton(
            key: const ValueKey('bitir-vazgec'),
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            key: const ValueKey('bitir-onay'),
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(s.t('confirmFinish')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
  }
  s.sinavBitir();
  ustuneKaydir(context);
}

class _Sonuc extends StatefulWidget {
  const _Sonuc({required this.sinav, required this.onBasla, required this.onYanlisCalis});
  final Sinav sinav;
  final VoidCallback onBasla;
  final VoidCallback onYanlisCalis;

  @override
  State<_Sonuc> createState() => _SonucDurumu();
}

class _SonucDurumu extends State<_Sonuc> {
  Timer? _gecis;

  @override
  void initState() {
    super.initState();
    _gecisPlanla();
  }

  @override
  void didUpdateWidget(_Sonuc eski) {
    super.didUpdateWidget(eski);
    if (!identical(eski.sinav, widget.sinav)) _gecisPlanla();
  }

  /// Geçiş reklamı: önce sonuç ekranı çizilir, ilk kareden [gecisGecikmesi] sonra (yüklüyse) reklam gelir.
  /// Kullanıcı o arada dokunursa, sayfadan çıkarsa veya üstüne başka sayfa (ör. Premium) açılırsa gösterilmez;
  /// sınav bekleyen olarak kalır ve sonuç ekranı yeniden açıldığında denenir.
  void _gecisPlanla() {
    _gecis?.cancel();
    final x = widget.sinav;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = DurumKapsami.oku(context);
      if (!s.gecisBekliyor(x)) return;
      if (!s.reklam.etkin) {
        s.sonucGosterildi(x); // reklam kapalı (Premium, test): bekleyen işaret temizlenir, reklam yok
        return;
      }
      _gecis = Timer(gecisGecikmesi, () {
        _gecis = null;
        if (!mounted) return;
        final enUstte = ModalRoute.of(context)?.isCurrent ?? true;
        if (gecisGosterilebilir(sayfaEnUstte: enUstte, ayniSinav: identical(widget.sinav, x), bekliyor: s.gecisBekliyor(x))) {
          s.sonucGosterildi(x);
        }
      });
    });
  }

  /// Kullanıcı sonuç ekranına dokundu (ör. Premium düğmesi): bekleyen reklam zamanlayıcısı iptal.
  void _gecisIptal() {
    _gecis?.cancel();
    _gecis = null;
  }

  @override
  void deactivate() {
    _gecisIptal(); // sayfadan/sekmeden çıkıldı
    super.deactivate();
  }

  @override
  void dispose() {
    _gecis?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    final r = Renk.of(context);
    final x = widget.sinav;
    final onBasla = widget.onBasla;
    final onYanlisCalis = widget.onYanlisCalis;
    final puan = x.puan;
    final gecti = x.gecti;
    final yanlis = x.sorular.length - puan;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _gecisIptal(),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        Kart(
          key: const ValueKey('sonuc'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Semantics(
                  liveRegion: true,
                  child: Etiket(
                    gecti ? s.t('passed') : s.t('failed'),
                    zemin: gecti ? r.dogruZemin : r.yanlisZemin,
                    yazi: gecti ? r.dogru : r.yanlis,
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '$puan / $sinavSoruSayisi',
                    key: const ValueKey('puan'),
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              Text(s.t('score', {'n': puan})),
              Text(
                s.t('wrongCount', {'n': yanlis}),
                key: const ValueKey('yanlis-adet'),
                style: TextStyle(fontWeight: FontWeight.w700, color: yanlis > 0 ? r.yanlis : r.dogru),
              ),
              if (gecti) Text(s.t('passCongrats')),
              if (yanlis > 0)
                FilledButton(
                  key: const ValueKey('yanlis-calis'),
                  onPressed: onYanlisCalis,
                  child: Text(s.t('studyWrongs', {'n': yanlis})),
                ),
              OutlinedButton(key: const ValueKey('tekrar'), onPressed: onBasla, child: Text(s.t('again'))),
            ],
          ),
        ),
        if (!s.premium) _Teklif(yanlis: yanlis, kaldi: !gecti),
        SolukMetin(s.t('review')),
        NumaraSeridi(sinav: x),
        Kart(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              SolukMetin(s.t('q', {'a': x.sira + 1, 'b': x.sorular.length})),
              SoruKarti(
                soru: x.sorular[x.sira],
                mod: KartModu.inceleme,
                secim: x.cevaplar[x.sira],
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }
}

/// Sonuç anındaki Premium teklifi: kaldıysa vurgulu, geçtiyse sade.
class _Teklif extends StatelessWidget {
  const _Teklif({required this.yanlis, required this.kaldi});
  final int yanlis;
  final bool kaldi;

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    final r = Renk.of(context);
    final fiyat = s.billing.fiyat;
    final kilitli = yanlis - ucretsizYanlis;
    return Container(
      key: const ValueKey('sonuc-teklif'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kaldi ? r.yanlisZemin : r.sayfa,
        border: Border.all(color: kaldi ? r.yanlis : r.cizgi, width: kaldi ? 1.5 : 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Baslik(kilitli > 0 ? s.t('offerPersonal', {'n': kilitli}) : s.t('offerGeneric')),
          if (kaldi) Text(s.t('failHint')),
          if (kilitli > 0) SolukMetin(s.t('firstFree', {'n': ucretsizYanlis})),
          FilledButton(
            key: const ValueKey('sonuc-premium'),
            onPressed: () => premiumAc(context),
            child: Text(fiyat != null ? s.t('buyShort', {'p': fiyat}) : s.t('open')),
          ),
        ],
      ),
    );
  }
}

/// 33 kutuluk numara şeridi (11 sütun). Sınavda cevaplananlar dolu, sonuçta doğru/yanlış renkli.
class NumaraSeridi extends StatelessWidget {
  const NumaraSeridi({super.key, required this.sinav});
  final Sinav sinav;

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.oku(context);
    final r = Renk.of(context);
    final x = sinav;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GridView.count(
        primary: false,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 11,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: [
          for (var i = 0; i < x.sorular.length; i++) _kutu(context, s, r, x, i),
        ],
      ),
    );
  }

  /// Sonuçta yanlış/boş kutu dolu `yanlis` zeminle çizilir: doğru kutudan renk tonunun yanında
  /// açıklık farkıyla da ayrılır (renk körlüğü). Ekran okuyucu numarayla birlikte sonucu okur.
  Widget _kutu(BuildContext context, AppState s, Renk r, Sinav x, int i) {
    final no = i + 1;
    final cevap = x.cevaplar[i];
    final Color zemin, yazi, kenar;
    final String etiket;
    if (x.bitti) {
      final dogru = cevap == x.sorular[i].dogru;
      zemin = dogru ? r.dogruZemin : r.yanlis;
      yazi = dogru ? r.dogru : r.sayfa;
      kenar = dogru ? r.dogru : r.yanlis;
      etiket = s.t(dogru ? 'boxRight' : (cevap == null ? 'boxEmpty' : 'boxWrong'), {'n': no});
    } else {
      zemin = cevap != null ? r.yazi : Colors.transparent;
      yazi = cevap != null ? r.kagit : r.soluk;
      kenar = cevap != null ? r.yazi : r.cizgi;
      etiket = s.t(cevap != null ? 'boxAnswered' : 'boxEmpty', {'n': no});
    }
    return _Kutu(
      key: ValueKey('kutu-$i'),
      no: no,
      etiket: etiket,
      simdi: i == x.sira,
      zemin: zemin,
      yazi: yazi,
      kenar: kenar,
      vurgu: r.vurgu,
      onTap: () {
        s.sinavGit(i);
        ustuneKaydir(context);
      },
    );
  }
}

class _Kutu extends StatelessWidget {
  const _Kutu({
    super.key,
    required this.no,
    required this.etiket,
    required this.simdi,
    required this.zemin,
    required this.yazi,
    required this.kenar,
    required this.vurgu,
    required this.onTap,
  });

  final int no;
  final String etiket;
  final bool simdi;
  final Color zemin, yazi, kenar, vurgu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: simdi,
        label: etiket,
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: zemin,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: simdi ? vurgu : kenar, width: simdi ? 2.5 : 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('$no', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: yazi)),
              ),
            ),
          ),
        ),
      );
}
