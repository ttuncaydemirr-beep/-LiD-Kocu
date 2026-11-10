// LiD Koçu — satın alma kararları. Eklentiden bağımsız saf fonksiyonlar; test/billing_karar_test.dart sınar.
import 'dart:async';

enum SatinAlmaSonucu { alindi, bekliyor, iptal, hata, yok }

/// Play'den gelen bir kaydın eklentiden bağımsız hâli.
enum AlimDurumu { bekliyor, alindi, geriYuklendi, iptal, hata }

class AlimKaydi {
  final String urun;
  final AlimDurumu durum;

  /// Play'e göre gerçekten ödenmiş mi (purchaseState == PURCHASED). Bekleyen ödeme false'tur.
  final bool gercek;
  const AlimKaydi(this.urun, this.durum, {this.gercek = true});
}

class AlimOzeti {
  final bool alindi, bekliyor, iptal, hata;

  /// Bu güncelleme bir geri yükleme (sahiplik sorgusu) yanıtı mı.
  final bool geriYukleme;
  const AlimOzeti({
    this.alindi = false,
    this.bekliyor = false,
    this.iptal = false,
    this.hata = false,
    this.geriYukleme = false,
  });
}

/// purchaseStream'den gelen listeyi özetler.
/// İptal ve hata kayıtları Android'de boş ürün kimliğiyle gelir; bu yüzden ürün kimliğine bakılmadan sayılır.
/// Boş liste yalnızca geri yüklemeden gelir ("hiç satın alma yok").
AlimOzeti ozetle(List<AlimKaydi> liste, String urunId) {
  var alindi = false, bekliyor = false, iptal = false, hata = false;
  var geri = liste.isEmpty;
  for (final p in liste) {
    switch (p.durum) {
      case AlimDurumu.iptal:
        iptal = true;
        continue;
      case AlimDurumu.hata:
        hata = true;
        continue;
      case AlimDurumu.geriYuklendi:
        geri = true;
      case AlimDurumu.alindi:
      case AlimDurumu.bekliyor:
        break;
    }
    if (p.urun != urunId) continue;
    switch (p.durum) {
      case AlimDurumu.alindi:
      case AlimDurumu.geriYuklendi:
        if (p.gercek) {
          alindi = true;
        } else {
          bekliyor = true;
        }
      case AlimDurumu.bekliyor:
        bekliyor = true;
      case AlimDurumu.iptal:
      case AlimDurumu.hata:
        break;
    }
  }
  return AlimOzeti(alindi: alindi, bekliyor: bekliyor && !alindi, iptal: iptal, hata: hata, geriYukleme: geri);
}

/// Satın alma akışının sonucu. İptal sessizdir (arayüz mesaj göstermez).
SatinAlmaSonucu satinAlmaSonucu(AlimOzeti o) {
  if (o.alindi) return SatinAlmaSonucu.alindi;
  if (o.bekliyor) return SatinAlmaSonucu.bekliyor;
  if (o.iptal) return SatinAlmaSonucu.iptal;
  return SatinAlmaSonucu.hata;
}

/// Geri yükleme yanıtına göre yeni sahiplik; null = kayıtlı değeri koru.
///  - Sahip: true.
///  - Bekleyen ödeme: değiştirme (henüz ödenmedi ama iade de değil).
///  - Sahip değil: yalnızca Play'e gerçekten ulaşıldıysa ([agDogrulandi]) ve yanıt, istek gönderildikten sonra
///    yapılan bir satın almadan eski değilse ([eskiIstek] false) false. Çevrimdışı boş yanıt Premium'u silmez.
bool? geriYuklemeKarari(AlimOzeti o, {required bool agDogrulandi, required bool eskiIstek}) {
  if (o.alindi) return true;
  if (o.bekliyor) return null;
  if (eskiIstek || !agDogrulandi) return null;
  return false;
}

/// [dene] true dönene kadar en fazla [deneme] kez çalıştırır; aralarda [bekleme] kadar bekler.
/// İstisna başarısız deneme sayılır.
Future<bool> tekrarla(
  Future<bool> Function() dene, {
  int deneme = 3,
  Duration Function(int denemeNo) bekleme = _ustelBekleme,
}) async {
  for (var i = 0; i < deneme; i++) {
    try {
      if (await dene()) return true;
    } catch (_) {}
    if (i < deneme - 1) await Future<void>.delayed(bekleme(i));
  }
  return false;
}

Duration _ustelBekleme(int i) => Duration(seconds: 2 << i);
