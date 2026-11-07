// LiD Koçu — Google Play Billing: tek seferlik, tüketilmeyen ürün "premium".
// Arrowtile billing_service.dart ile aynı mantık:
//  - Açılışta sahiplik sessizce sorgulanır (restorePurchases → purchaseStream).
//  - PURCHASED → hak verilir ve onaylanır (3 gün içinde onaylanmayan satın alma iade edilir).
//  - PENDING → hak verilmez; "ödeme bekleniyor" denir.
//  - Sunucu doğrulaması yoktur (sunucusuz uygulama).
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart' show PurchaseStateWrapper;
import 'package:in_app_purchase_android/in_app_purchase_android.dart' show GooglePlayPurchaseDetails;

/// Play Console > Para kazanma > Uygulama içi ürünler: bu kimlikle tek seferlik ürün oluşturun.
const String premiumUrunId = 'premium';

enum SatinAlmaSonucu { alindi, bekliyor, iptal, hata, yok }

class Billing {
  // Geç oluşturulur: testlerde ve Play olmayan ortamda eklentiye dokunulmaz.
  late final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _urun;
  Completer<SatinAlmaSonucu>? _alim;
  Completer<bool?>? _geri;
  bool _hazir = false;

  bool sahip;
  void Function(bool sahip)? degisti;

  Billing({this.sahip = false});

  bool get hazir => _hazir;

  /// Mağazanın yerel para birimindeki fiyatı (ör. "6,99 €"); bilinmiyorsa null.
  String? get fiyat => _urun?.price;

  Future<void> baslat() async {
    try {
      _hazir = await _iap.isAvailable();
      _sub = _iap.purchaseStream.listen(_gelen, onError: (Object e) {
        if (kDebugMode) debugPrint('purchaseStream: $e');
      });
      if (_hazir) {
        unawaited(_urunAl());
        unawaited(geriYukle());
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Billing.baslat: $e');
      _hazir = false;
    }
  }

  void kapat() {
    _sub?.cancel();
    _sub = null;
  }

  Future<ProductDetails?> _urunAl() async {
    try {
      final r = await _iap.queryProductDetails({premiumUrunId});
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

  Future<SatinAlmaSonucu> satinAl() async {
    if (!_hazir) return SatinAlmaSonucu.yok;
    final pd = _urun ?? await _urunAl();
    if (pd == null) return SatinAlmaSonucu.hata;
    _alim?.complete(SatinAlmaSonucu.hata);
    final c = Completer<SatinAlmaSonucu>();
    _alim = c;
    try {
      final basladi = await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: pd));
      if (!basladi) {
        _alim = null;
        final o = await geriYukle(); // çoğunlukla ITEM_ALREADY_OWNED
        return o == true ? SatinAlmaSonucu.alindi : SatinAlmaSonucu.hata;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('buyNonConsumable: $e');
      _alim = null;
      return SatinAlmaSonucu.hata;
    }
    return c.future;
  }

  /// true/false = Play'in yanıtı, null = sorgu başarısız (kayıtlı değer korunur).
  Future<bool?> geriYukle() async {
    if (!_hazir) return null;
    _geri?.complete(null);
    final c = Completer<bool?>();
    _geri = c;
    try {
      await _iap.restorePurchases();
    } catch (e) {
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

  Future<void> _gelen(List<PurchaseDetails> liste) async {
    var alindi = false, bekliyor = false, hata = false, iptal = false, geri = false;
    for (final p in liste) {
      if (p.productID != premiumUrunId) {
        if (p.pendingCompletePurchase) {
          try {
            await _iap.completePurchase(p);
          } catch (_) {}
        }
        continue;
      }
      if (p.status == PurchaseStatus.restored) geri = true;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (_gercek(p)) {
            alindi = true;
            if (p.pendingCompletePurchase) {
              try {
                await _iap.completePurchase(p);
              } catch (e) {
                if (kDebugMode) debugPrint('completePurchase: $e');
              }
            }
          } else {
            bekliyor = true;
          }
        case PurchaseStatus.pending:
          bekliyor = true;
        case PurchaseStatus.canceled:
          iptal = true;
        case PurchaseStatus.error:
          hata = true;
      }
    }
    final pc = _alim;
    if (pc != null && !pc.isCompleted && liste.isNotEmpty) {
      _alim = null;
      if (alindi) {
        _sahipYap(true);
        pc.complete(SatinAlmaSonucu.alindi);
      } else if (bekliyor) {
        pc.complete(SatinAlmaSonucu.bekliyor);
      } else if (iptal) {
        pc.complete(SatinAlmaSonucu.iptal);
      } else {
        pc.complete(hata ? SatinAlmaSonucu.hata : SatinAlmaSonucu.hata);
      }
    } else if (alindi) {
      _sahipYap(true);
    }
    final rc = _geri;
    if (rc != null && !rc.isCompleted && (liste.isEmpty || geri)) {
      _geri = null;
      _sahipYap(alindi);
      rc.complete(alindi);
    }
  }
}
