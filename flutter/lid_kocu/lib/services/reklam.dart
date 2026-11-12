// LiD Koçu — AdMob reklamları ve Google UMP rızası (AB/AEA/İsviçre).
//  - Premium kullanıcıda hiçbir şey başlatılmaz: ne UMP formu ne reklam SDK'sı. Satın alınca kapat() her şeyi kaldırır.
//  - Açılışta rıza bilgisi güncellenir, gerekirse form gösterilir; reklam isteği yalnızca canRequestAds true iken yapılır.
//  - Geçiş ve ödüllü reklam önceden yüklenir; yüklü değilse gösterilmez (sessizce atlanır).
//  - Kararlar eklentiden bağımsız: reklam_karar.dart. Kimlikler: reklam_ayar.dart.
//  - Testlerde ve Play olmayan ortamda baslat() çağrılmaz; eklentiye hiç dokunulmaz (Billing'deki desen).
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';

import 'olcum.dart';
import 'reklam_ayar.dart';
import 'reklam_karar.dart';

export 'reklam_karar.dart' show ReklamTuru;

/// Sayfa içeriğinin en geniş hâli (ui/app.dart: 620 genişlik, iki yanda 16 boşluk).
const double _icerikGenislik = 620;
const double _yanBosluk = 16;

/// Banner boyutu bilinmeden önce ayrılan yükseklik.
const double varsayilanBannerYuksekligi = 62;

class Reklam {
  Reklam({
    required this.olcum,
    required this.premium,
    required this.kontrolGrubu,
    required this.odulluIstenir,
    double? bannerYukseklik,
    this.bannerYukseklikKaydet,
  }) : _bannerYukseklik = bannerYukseklik;

  final Olcum olcum;
  final bool Function() premium;
  final bool Function() kontrolGrubu;

  /// Bugün ödüllü reklamla ek hak açılabilir mi (günlük sınır); değilse ödüllü reklam yüklenmez.
  final bool Function() odulluIstenir;
  final void Function(double yukseklik)? bannerYukseklikKaydet;

  /// Durum değişti (rıza, SDK hazır, reklam yüklendi/gösterildi); arayüz yenilensin.
  VoidCallback? degisti;

  bool _baslatildi = false;
  bool _kapali = false;
  bool _rizaBitti = false;
  bool _rizaTamam = false;
  bool _gizlilikGerekli = false;
  bool _sdkHazir = false;
  Future<void>? _sdk;
  bool _tamEkran = false;

  InterstitialAd? _gecis;
  bool _gecisYukleniyor = false;
  int _gecisHata = 0;
  RewardedAd? _odullu;
  bool _odulluYukleniyor = false;
  int _odulluHata = 0;

  AdSize? _bannerBoyut;
  double? _bannerYukseklik;

  static bool get _test => kDebugMode || testReklamZorla;

  /// Reklam altyapısı istendi ve kapatılmadı (Premium değil, test ortamı değil).
  bool get etkin => _baslatildi && !_kapali && !premium();

  /// Ayarlar/alt bilgide "Gizlilik seçenekleri" girişi gösterilmeli mi.
  bool get gizlilikGerekli => etkin && _gizlilikGerekli;

  /// Banner boyutu (SDK başlayınca hesaplanır).
  AdSize? get bannerBoyut => _bannerBoyut;

  /// Banner için ayrılan sabit yükseklik: bilinen boyut, yoksa önceki açılıştan kayıtlı, yoksa varsayılan.
  double get bannerYukseklik =>
      _bannerBoyut?.height.toDouble() ?? _bannerYukseklik ?? varsayilanBannerYuksekligi;

  String? birim(ReklamTuru t) => switch (t) {
        ReklamTuru.banner =>
          birimSec(test: _test, uygulama: admobUygulamaKimligi, testBirim: testBannerBirimi, gercekBirim: bannerBirimi),
        ReklamTuru.gecis =>
          birimSec(test: _test, uygulama: admobUygulamaKimligi, testBirim: testGecisBirimi, gercekBirim: gecisBirimi),
        ReklamTuru.odullu =>
          birimSec(test: _test, uygulama: admobUygulamaKimligi, testBirim: testOdulluBirimi, gercekBirim: odulluBirimi),
      };

  bool _kosul(ReklamTuru t, {required bool riza}) => reklamUygun(
        t,
        premium: premium(),
        kontrolGrubu: kontrolGrubu(),
        uzakAcik: olcum.bayrak(uzakAnahtar(t)),
        rizaTamam: riza,
        kimlikVar: birim(t) != null,
      );

  /// Bu tür reklam şu an istenebilir mi (SDK hazır, rıza tamam, kararlar uygun).
  bool uygun(ReklamTuru t) => etkin && _sdkHazir && _kosul(t, riza: _rizaTamam);

  /// Ana sayfada banner yeri ayrılmalı mı. Rıza beklenirken de ayrılır ki reklam gelince ekran zıplamasın.
  bool get bannerAlani => etkin && _kosul(ReklamTuru.banner, riza: !_rizaBitti || _rizaTamam);

  /// Ödüllü reklam seçeneği bu kullanıcıya sunulur mu (yüklü olmasa da; o zaman düğme pasif olur).
  bool get odulluSecenek => etkin && _kosul(ReklamTuru.odullu, riza: !_rizaBitti || _rizaTamam);

  /// Ödüllü reklam yüklü ve gösterilebilir.
  bool get odulluHazir => _odullu != null && !_tamEkran && uygun(ReklamTuru.odullu);

  void _bildir() {
    if (!_kapali) degisti?.call();
  }

  /// UMP'nin yazdığı TCF amaç dizisi (Android varsayılan SharedPreferences, ön ek yok).
  static Future<String?> _tcfAmaclar() async {
    try {
      const secenek = SharedPreferencesAsyncAndroidOptions(
        backend: SharedPreferencesAndroidBackendLibrary.SharedPreferences,
        originalSharedPreferencesOptions: AndroidSharedPreferencesStoreOptions(),
      );
      return await SharedPreferencesAsync(options: secenek).getString('IABTCF_PurposeConsents');
    } catch (e) {
      if (kDebugMode) debugPrint('IABTCF: $e');
      return null;
    }
  }

  static RizaDurumu _durum(ConsentStatus s) => switch (s) {
        ConsentStatus.notRequired => RizaDurumu.gerekmiyor,
        ConsentStatus.obtained => RizaDurumu.alindi,
        ConsentStatus.required => RizaDurumu.gerekli,
        ConsentStatus.unknown => RizaDurumu.bilinmiyor,
      };

  /// UMP durumunu okuyup Analytics rızasını (Consent Mode v2) uygular.
  Future<void> _analyticsRizasi() async {
    var durum = RizaDurumu.bilinmiyor;
    try {
      durum = _durum(await ConsentInformation.instance.getConsentStatus());
    } catch (e) {
      if (kDebugMode) debugPrint('UMP durum: $e');
    }
    final tcf = durum == RizaDurumu.alindi ? await _tcfAmaclar() : null;
    olcum.rizaUygula(analyticsRizasi(durum: durum, tcfAmaclar: tcf, premium: premium()));
  }

  /// Premium: form gösterilmez, reklam SDK'sı başlamaz. Yalnızca rıza bilgisi güncellenip bölge/durum okunur
  /// (AEA dışı ise analytics_storage granted; bilinmiyorsa veya rıza gerekli ve alınmamışsa denied kalır).
  Future<void> _premiumRiza() async {
    try {
      final bitti = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          if (!bitti.isCompleted) bitti.complete();
        },
        (FormError e) {
          if (!bitti.isCompleted) bitti.complete();
        },
      );
      await bitti.future.timeout(const Duration(seconds: 20));
    } catch (e) {
      if (kDebugMode) debugPrint('UMP (Premium): $e');
    }
    await _analyticsRizasi();
  }

  /// Açılışta beklenmeden çağrılır. Premium'da form ve reklam SDK'sı yok; yalnızca Analytics rızası okunur.
  Future<void> baslat() async {
    if (_baslatildi || _kapali) return;
    if (!reklamSdkGerekli(premium: premium())) {
      _kapali = true; // Premium: reklam tarafı bu oturumda hiç başlamaz
      await _premiumRiza();
      return;
    }
    _baslatildi = true;
    _bildir();
    try {
      final ci = ConsentInformation.instance;
      // Önceki oturumda rıza alındıysa reklamlar güncellemeyi beklemeden hazırlanır.
      if (await ci.canRequestAds()) {
        _rizaTamam = true;
        unawaited(_sdkBaslat());
      }
      final bitti = Completer<void>();
      ci.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            if (etkin) {
              await ConsentForm.loadAndShowConsentFormIfRequired((FormError? e) {
                if (e != null && kDebugMode) debugPrint('UMP formu: ${e.message}');
              });
            }
          } catch (e) {
            if (kDebugMode) debugPrint('UMP formu: $e');
          }
          if (!bitti.isCompleted) bitti.complete();
        },
        (FormError e) {
          if (kDebugMode) debugPrint('UMP güncelleme: ${e.message}');
          if (!bitti.isCompleted) bitti.complete();
        },
      );
      await bitti.future;
      _rizaTamam = await ci.canRequestAds();
      _gizlilikGerekli =
          await ci.getPrivacyOptionsRequirementStatus() == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      if (kDebugMode) debugPrint('UMP: $e');
    }
    _rizaBitti = true;
    await _analyticsRizasi();
    _bildir();
    if (_rizaTamam && etkin) await _sdkBaslat();
  }

  Future<void> _sdkBaslat() => _sdk ??= () async {
        try {
          await MobileAds.instance.initialize();
        } catch (e) {
          if (kDebugMode) debugPrint('MobileAds.initialize: $e');
          _sdk = null;
          return;
        }
        if (!etkin) return;
        _sdkHazir = true;
        await _bannerBoyutHesapla();
        _bildir();
        hazirla();
      }();

  Future<void> _bannerBoyutHesapla() async {
    try {
      final v = PlatformDispatcher.instance.views.first;
      final ekran = v.physicalSize.width / v.devicePixelRatio;
      final genislik = (ekran.clamp(0.0, _icerikGenislik) - 2 * _yanBosluk).truncate();
      if (genislik <= 0) return;
      final b = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(genislik);
      if (b == null) return;
      _bannerBoyut = b;
      if (_bannerYukseklik != b.height.toDouble()) {
        _bannerYukseklik = b.height.toDouble();
        bannerYukseklikKaydet?.call(_bannerYukseklik!);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Banner boyutu: $e');
    }
  }

  /// Uygun olan tam ekran reklamları önceden yükler (Remote Config veya rıza değişince de çağrılır).
  void hazirla() {
    _gecisYukle();
    _odulluYukle();
  }

  /// Hata sonrası yeniden deneme: 30 sn, 60 sn, 120 sn; sonra [yenile] (öne dönüş, teklif alanı) beklenir.
  void _sonraDene(int hata, VoidCallback f) {
    final d = yenidenDenemeSuresi(hata);
    if (d == null) return;
    Timer(d, () {
      if (etkin) f();
    });
  }

  /// Öne dönüşte ve ödüllü teklif alanı görününce: hata sayaçlarını sıfırlayıp eksik reklamları yeniden ister
  /// (ağ geri gelince ödüllü reklam o oturumda yine yüklenebilsin).
  void yenile() {
    if (!etkin) return;
    _gecisHata = 0;
    _odulluHata = 0;
    if (!_sdkHazir && _rizaTamam) {
      unawaited(_sdkBaslat());
      return;
    }
    hazirla();
  }

  void _gecisYukle() {
    final id = birim(ReklamTuru.gecis);
    if (_gecis != null || _gecisYukleniyor || id == null || !uygun(ReklamTuru.gecis)) return;
    _gecisYukleniyor = true;
    InterstitialAd.load(
      adUnitId: id,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _gecisYukleniyor = false;
          _gecisHata = 0;
          if (!etkin) {
            ad.dispose();
            return;
          }
          _gecis = ad;
        },
        onAdFailedToLoad: (e) {
          _gecisYukleniyor = false;
          if (kDebugMode) debugPrint('Geçiş reklamı yüklenemedi: ${e.code} ${e.message}');
          _sonraDene(++_gecisHata, _gecisYukle);
        },
      ),
    );
  }

  void _odulluYukle() {
    final id = birim(ReklamTuru.odullu);
    if (_odullu != null || _odulluYukleniyor || id == null || !uygun(ReklamTuru.odullu) || !odulluIstenir()) {
      return;
    }
    _odulluYukleniyor = true;
    RewardedAd.load(
      adUnitId: id,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _odulluYukleniyor = false;
          _odulluHata = 0;
          if (!etkin) {
            ad.dispose();
            return;
          }
          _odullu = ad;
          _bildir();
        },
        onAdFailedToLoad: (e) {
          _odulluYukleniyor = false;
          if (kDebugMode) debugPrint('Ödüllü reklam yüklenemedi: ${e.code} ${e.message}');
          _bildir();
          _sonraDene(++_odulluHata, _odulluYukle);
        },
      ),
    );
  }

  /// Sınav sonucu çizildikten sonra çağrılır. Yüklü değilse sessizce atlanır. Gösterildiyse true.
  bool gecisGoster() {
    final ad = _gecis;
    if (ad == null || _tamEkran || !uygun(ReklamTuru.gecis)) {
      _gecisHata = 0;
      _gecisYukle();
      return false;
    }
    _gecis = null;
    _tamEkran = true;
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (_) => olcum.olay('gecis_gosterildi'),
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _tamEkran = false;
        _gecisYukle();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        _tamEkran = false;
        _gecisYukle();
      },
    );
    unawaited(ad.show().catchError((Object e) {
      _tamEkran = false;
      if (kDebugMode) debugPrint('Geçiş reklamı: $e');
    }));
    return true;
  }

  /// Ödüllü reklamı gösterir. [odul], reklam tamamen izlenince (onUserEarnedReward) çağrılır.
  /// Dönen değer: reklam kapandığında ödül kazanılmış mıydı; reklam hiç gösterilemediyse [OdulluSonuc.gosterilemedi].
  Future<OdulluSonuc> odulluGoster(VoidCallback odul) async {
    final ad = _odullu;
    if (ad == null || _tamEkran || !uygun(ReklamTuru.odullu)) {
      _odulluHata = 0;
      _odulluYukle();
      return OdulluSonuc.gosterilemedi;
    }
    _odullu = null;
    _tamEkran = true;
    var kazandi = false;
    var gosterildi = false;
    final c = Completer<OdulluSonuc>();
    var kapandi = false;
    void bitir(Ad a) {
      if (kapandi) return;
      kapandi = true;
      a.dispose();
      _tamEkran = false;
      if (!c.isCompleted) {
        c.complete(kazandi
            ? OdulluSonuc.kazanildi
            : (gosterildi ? OdulluSonuc.kazanilmadi : OdulluSonuc.gosterilemedi));
      }
      _odulluYukle();
      _bildir();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (_) => gosterildi = true,
      onAdDismissedFullScreenContent: bitir,
      onAdFailedToShowFullScreenContent: (a, e) => bitir(a),
    );
    _bildir();
    try {
      await ad.show(onUserEarnedReward: (_, _) {
        if (kazandi) return;
        kazandi = true;
        odul();
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Ödüllü reklam: $e');
      bitir(ad);
    }
    return c.future;
  }

  /// "Gizlilik seçenekleri": UMP gizlilik formunu yeniden açar.
  Future<void> gizlilikSecenekleri() async {
    if (!etkin) return;
    try {
      await ConsentForm.showPrivacyOptionsForm((FormError? e) {
        if (e != null && kDebugMode) debugPrint('Gizlilik formu: ${e.message}');
      });
      final ci = ConsentInformation.instance;
      _rizaTamam = await ci.canRequestAds();
      _gizlilikGerekli =
          await ci.getPrivacyOptionsRequirementStatus() == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      if (kDebugMode) debugPrint('Gizlilik formu: $e');
    }
    await _analyticsRizasi();
    _bildir();
    if (_rizaTamam && etkin) {
      await _sdkBaslat();
      hazirla();
    }
  }

  /// Premium alındı: bütün reklamlar kalkar, yenisi istenmez.
  void kapat() {
    if (_kapali) return;
    degisti?.call();
    _kapali = true;
    _gecis?.dispose();
    _gecis = null;
    _odullu?.dispose();
    _odullu = null;
  }
}
