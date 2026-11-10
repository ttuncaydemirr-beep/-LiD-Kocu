// LiD Koçu — Google Play Billing: tek seferlik, tüketilmeyen ürün "premium".
//  - Açılışta ve uygulama ön plana her döndüğünde sahiplik sessizce sorgulanır (restorePurchases → purchaseStream):
//    bekleyen ödemenin tamamlanması, iade ve onaylanmamış satın almalar böyle yakalanır.
//  - PURCHASED → hak verilir ve onaylanır (3 gün içinde onaylanmayan satın alma iade edilir). Onay sonucu
//    (BillingResultWrapper.responseCode) kontrol edilir; başarısızsa birkaç kez, sonra her ön plana dönüşte yeniden denenir.
//  - PENDING → hak verilmez; "ödeme bekleniyor" denir.
//  - Kararlar eklentiden bağımsız: billing_karar.dart. Sunucu doğrulaması yoktur (sunucusuz uygulama).
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart'
    show BillingResponse, BillingResultWrapper, PurchaseStateWrapper;
import 'package:in_app_purchase_android/in_app_purchase_android.dart' show GooglePlayPurchaseDetails;

import 'billing_karar.dart';

export 'billing_karar.dart' show SatinAlmaSonucu;

/// Play Console > Para kazanma > Uygulama içi ürünler: bu kimlikle tek seferlik ürün oluşturun.
const String premiumUrunId = 'premium';

class Billing {
  // Geç oluşturulur: testlerde ve Play olmayan ortamda eklentiye dokunulmaz.
  late final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _urun;
  Completer<SatinAlmaSonucu>? _alim;
  Completer<bool?>? _geri;
  bool _baslatildi = false;
  bool _hazir = false;
  bool _bekleyenVar = false;
  Future<bool>? _baglanti;
  DateTime? _sonYenileme;

  /// Her başarılı satın almada artar; eski (satın almadan önce gönderilmiş) geri yükleme yanıtlarını ayırt eder.
  int _alimSira = 0;
  int _geriSira = 0;
  final Set<String> _onaylaniyor = {};

  bool sahip;
  void Function(bool sahip)? degisti;

  Billing({this.sahip = false});

  bool get hazir => _hazir;

  /// Play'de ödemesi beklenen bir Premium satın alması var.
  bool get bekleyenVar => _bekleyenVar;

  /// Mağazanın yerel para birimindeki fiyatı (ör. "6,99 €"); bilinmiyorsa null.
  String? get fiyat => _urun?.price;

  /// Uygulama açılışında çağrılır; beklenmeden (unawaited) çalışabilir.
  Future<void> baslat() async {
    _baslatildi = true;
    try {
      _sub ??= _iap.purchaseStream.listen(_gelen, onError: (Object e) {
        if (kDebugMode) debugPrint('purchaseStream: $e');
      });
    } catch (e) {
      if (kDebugMode) debugPrint('purchaseStream: $e');
    }
    await _baglan();
  }

  /// Billing hazır değilse yeniden bağlanmayı dener. Aynı anda tek deneme yapılır.
  Future<bool> _baglan() {
    if (_hazir) return Future.value(true);
    return _baglanti ??= () async {
      try {
        _hazir = await _iap.isAvailable().timeout(const Duration(seconds: 10));
      } catch (e) {
        if (kDebugMode) debugPrint('Billing.isAvailable: $e');
        _hazir = false;
      }
      _baglanti = null;
      if (_hazir) {
        unawaited(_urunAl());
        unawaited(geriYukle());
      }
      return _hazir;
    }();
  }

  /// Uygulama ön plana döndüğünde: bağlantıyı yeniden dene ve sahipliği sessizce yenile
  /// (bekleyen ödeme tamamlandı mı, iade edildi mi, onaylanmamış satın alma var mı).
  Future<void> yenile() async {
    if (!_baslatildi) return;
    final simdi = DateTime.now();
    final son = _sonYenileme;
    if (son != null && simdi.difference(son) < const Duration(seconds: 10)) return;
    _sonYenileme = simdi;
    if (!_hazir) {
      await _baglan(); // başarılıysa geri yüklemeyi kendisi başlatır
      return;
    }
    if (_alim != null) return; // satın alma akışı sürüyor; sonucu purchaseStream getirir
    await geriYukle();
  }

  void kapat() {
    _sub?.cancel();
    _sub = null;
  }

  Future<ProductDetails?> _urunAl() async {
    try {
      final r = await _iap.queryProductDetails({premiumUrunId}).timeout(const Duration(seconds: 15));
      if (r.error != null || r.productDetails.isEmpty) return null;
      _urun = r.productDetails.first;
      degisti?.call(sahip); // fiyat geldi; arayüz yenilensin
      return _urun;
    } catch (e) {
      if (kDebugMode) debugPrint('queryProductDetails: $e');
      return null;
    }
  }

  void _sahipYap(bool v) {
    if (v == sahip) return;
    sahip = v;
    degisti?.call(v);
  }

  /// Geri yüklemeden sonra bilinen duruma göre sonuç.
  SatinAlmaSonucu _durumdanSonuc(SatinAlmaSonucu yoksa) =>
      sahip ? SatinAlmaSonucu.alindi : (_bekleyenVar ? SatinAlmaSonucu.bekliyor : yoksa);

  Future<SatinAlmaSonucu> satinAl() async {
    if (!_hazir && !await _baglan()) return SatinAlmaSonucu.yok;
    if (_bekleyenVar) {
      // Bekleyen ödeme varken Play yeni akışı reddeder: önce durumu tazele.
      await geriYukle();
      if (sahip || _bekleyenVar) return _durumdanSonuc(SatinAlmaSonucu.bekliyor);
    }
    final pd = _urun ?? await _urunAl();
    if (pd == null) return SatinAlmaSonucu.hata;
    _alim?.complete(SatinAlmaSonucu.hata);
    final c = Completer<SatinAlmaSonucu>();
    _alim = c;
    try {
      final basladi = await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: pd));
      if (!basladi) {
        if (identical(_alim, c)) _alim = null;
        await geriYukle(); // çoğunlukla ITEM_ALREADY_OWNED veya bekleyen ödeme
        return _durumdanSonuc(SatinAlmaSonucu.hata);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('buyNonConsumable: $e');
      if (identical(_alim, c)) _alim = null;
      await geriYukle();
      return _durumdanSonuc(SatinAlmaSonucu.hata);
    }
    return c.future.timeout(const Duration(minutes: 3), onTimeout: () async {
      if (identical(_alim, c)) _alim = null;
      await geriYukle();
      return _durumdanSonuc(SatinAlmaSonucu.hata);
    });
  }

  /// true/false = Play'in yanıtı, null = sorgu başarısız veya kesin değil (kayıtlı değer korunur).
  Future<bool?> geriYukle() async {
    if (!_hazir && !await _baglan()) return null;
    _geri?.complete(null);
    final c = Completer<bool?>();
    _geri = c;
    _geriSira = _alimSira;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      if (kDebugMode) debugPrint('restorePurchases: $e');
      if (identical(_geri, c)) _geri = null;
      if (!c.isCompleted) c.complete(null);
      return null;
    }
    return c.future.timeout(const Duration(seconds: 20), onTimeout: () {
      if (identical(_geri, c)) _geri = null;
      return null;
    });
  }

  bool _gercek(PurchaseDetails p) {
    if (p is GooglePlayPurchaseDetails) {
      return p.billingClientPurchase.purchaseState == PurchaseStateWrapper.purchased;
    }
    return p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored;
  }

  static AlimDurumu _durum(PurchaseStatus s) => switch (s) {
        PurchaseStatus.pending => AlimDurumu.bekliyor,
        PurchaseStatus.purchased => AlimDurumu.alindi,
        PurchaseStatus.restored => AlimDurumu.geriYuklendi,
        PurchaseStatus.canceled => AlimDurumu.iptal,
        PurchaseStatus.error => AlimDurumu.hata,
      };

  /// Tek onay denemesi. Android'de completePurchase istisna atmaz, sonucu BillingResultWrapper olarak döndürür
  /// (InAppPurchase.completePurchase platformun Future'ını olduğu gibi geçirir).
  Future<bool> _tekOnay(PurchaseDetails p) async {
    final Future<void> f = _iap.completePurchase(p);
    if (f is Future<BillingResultWrapper>) {
      final r = await f;
      if (r.responseCode != BillingResponse.ok && kDebugMode) {
        debugPrint('completePurchase: ${r.responseCode} ${r.debugMessage}');
      }
      return r.responseCode == BillingResponse.ok;
    }
    await f;
    return true;
  }

  /// Onaylar; başarısızsa üstel aralıkla yeniden dener. Yine olmazsa bir sonraki geri yüklemede
  /// (ön plana dönüş, açılış) kayıt yeniden onaylanmamış gelir ve tekrar denenir.
  Future<void> _onayla(PurchaseDetails p) async {
    final kimlik = p.purchaseID ?? p.verificationData.serverVerificationData;
    if (!_onaylaniyor.add(kimlik)) return;
    try {
      final ok = await tekrarla(() => _tekOnay(p));
      if (!ok && kDebugMode) debugPrint('completePurchase: onaylanamadı, ön plana dönüşte yeniden denenecek');
    } finally {
      _onaylaniyor.remove(kimlik);
    }
  }

  Future<void> _gelen(List<PurchaseDetails> liste) async {
    final kayitlar = <AlimKaydi>[];
    for (final p in liste) {
      final gercek = _gercek(p);
      kayitlar.add(AlimKaydi(p.productID, _durum(p.status), gercek: gercek));
      final odendi = p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored;
      if (odendi && gercek && p.pendingCompletePurchase) unawaited(_onayla(p));
    }
    final o = ozetle(kayitlar, premiumUrunId);

    if (o.alindi) {
      _bekleyenVar = false;
      _alimSira++;
      _sahipYap(true);
    } else if (o.bekliyor) {
      _bekleyenVar = true;
    } else if (o.geriYukleme) {
      _bekleyenVar = false; // bekleyen ödeme iptal edildi veya zaman aşımına uğradı
    }

    // Satın alma akışının sonucu (geri yükleme yanıtı yalnızca sahiplik kesinse akışı bitirir).
    final pc = _alim;
    if (pc != null && !pc.isCompleted && (!o.geriYukleme || o.alindi)) {
      _alim = null;
      final r = satinAlmaSonucu(o);
      if (r == SatinAlmaSonucu.hata) {
        // ör. ITEM_ALREADY_OWNED veya bekleyen ödeme: gerçek durumu sorgulayıp öyle yanıtla.
        unawaited(geriYukle().then((_) => pc.complete(_durumdanSonuc(SatinAlmaSonucu.hata))));
      } else {
        pc.complete(r);
      }
    }

    if (!o.geriYukleme) return;
    final rc = _geri;
    if (identical(_geri, rc)) _geri = null;
    final eski = _geriSira != _alimSira && !o.alindi;
    final ag = (o.alindi || o.bekliyor || eski) ? false : (await _urunAl()) != null;
    final karar = geriYuklemeKarari(o, agDogrulandi: ag, eskiIstek: eski);
    if (karar != null) _sahipYap(karar);
    if (rc != null && !rc.isCompleted) rc.complete(karar ?? (o.bekliyor ? false : null));
  }
}
