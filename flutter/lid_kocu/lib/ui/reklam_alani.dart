// Reklam arayüzü: ana sayfa banner'ı ve "Reklam izle, 1 deneme daha aç" teklifi.
// Yalnızca Premium olmayanlara; kararlar services/reklam_karar.dart'ta.
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/reklam.dart';
import 'durum.dart';
import 'tema.dart';

/// Banner'ın üstünde bırakılan boşluk (en az 24 dp; üstteki sütun aralığına ek olarak).
const double bannerUstBosluk = 24;

/// Ana sayfada Premium kartının altındaki tek anchored adaptive banner.
/// Yüklenmeden önce de sabit yükseklikte yer tutar; yüklenemezse yer boş kalır (ekran zıplamaz).
class ReklamBanner extends StatefulWidget {
  const ReklamBanner({super.key});

  @override
  State<ReklamBanner> createState() => _ReklamBannerDurumu();
}

class _ReklamBannerDurumu extends State<ReklamBanner> {
  BannerAd? _ad;
  bool _yuklendi = false;
  bool _istendi = false;

  void _yukle(Reklam r) {
    if (_istendi || !mounted) return;
    final id = r.birim(ReklamTuru.banner);
    final boyut = r.bannerBoyut;
    if (id == null || boyut == null || !r.uygun(ReklamTuru.banner)) return;
    _istendi = true;
    final ad = BannerAd(
      adUnitId: id,
      size: boyut,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (a) {
          if (!mounted) {
            a.dispose();
            return;
          }
          setState(() => _yuklendi = true);
          r.olcum.olay('banner_yuklendi');
        },
        onAdFailedToLoad: (a, e) {
          a.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _yuklendi = false;
            });
          }
          r.olcum.olay('banner_yuklenemedi', {'kod': e.code});
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    _ad = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    final r = s.reklam;
    if (s.premium || !r.bannerAlani) return const SizedBox.shrink();
    if (!_istendi && r.uygun(ReklamTuru.banner)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _yukle(r));
    }
    final ad = _ad;
    return Padding(
      key: const ValueKey('banner-alani'),
      padding: const EdgeInsets.only(top: bannerUstBosluk),
      child: SizedBox(
        height: r.bannerYukseklik,
        width: double.infinity,
        child: (_yuklendi && ad != null)
            ? Center(
                child: SizedBox(
                  width: ad.size.width.toDouble(),
                  height: ad.size.height.toDouble(),
                  child: AdWidget(ad: ad),
                ),
              )
            : null,
      ),
    );
  }
}

/// Ücretsiz hak bitince Probetest ekranında: ödüllü reklamla 1 ek deneme.
class OdulluTeklif extends StatefulWidget {
  const OdulluTeklif({super.key, required this.onBasla});

  /// Ek hak açılınca "Sınavı başlat".
  final VoidCallback onBasla;

  @override
  State<OdulluTeklif> createState() => _OdulluTeklifDurumu();
}

class _OdulluTeklifDurumu extends State<OdulluTeklif> {
  bool _mesgul = false;

  Future<void> _izle() async {
    final s = DurumKapsami.oku(context);
    final m = ScaffoldMessenger.of(context);
    setState(() => _mesgul = true);
    bool ok;
    try {
      ok = await s.odulluIzle();
    } catch (_) {
      ok = false;
    }
    if (mounted) setState(() => _mesgul = false);
    m.showSnackBar(SnackBar(content: Text(s.t(ok ? 'rewardGranted' : 'rewardFail'))));
  }

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    if (s.premium) return const SizedBox.shrink();
    // Ek hak açıldı: hemen başlatılabilir.
    if (s.sinavAcik) {
      return Kart(
        key: const ValueKey('odullu-acildi'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            if (s.ekHakKalan > 0) Semantics(liveRegion: true, child: Text(s.t('rewardGranted'))),
            FilledButton(
              key: const ValueKey('odullu-basla'),
              onPressed: widget.onBasla,
              child: Text(s.t('startExam')),
            ),
          ],
        ),
      );
    }
    if (s.odulluSiniraUlasti) {
      return Kart(key: const ValueKey('odullu-sinir'), child: SolukMetin(s.t('rewardLimit')));
    }
    if (!s.odulluSunulur) return const SizedBox.shrink();
    final hazir = s.reklam.odulluHazir && !_mesgul;
    return Kart(
      key: const ValueKey('odullu'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          OutlinedButton.icon(
            key: const ValueKey('odullu-izle'),
            onPressed: hazir ? _izle : null,
            icon: const Icon(Icons.play_circle_outline),
            label: Text(s.t('rewardBtn')),
          ),
          if (!s.reklam.odulluHazir) SolukMetin(s.t('rewardNotReady')),
        ],
      ),
    );
  }
}
