// LiD Koçu — reklam kararları. Eklentiden bağımsız saf fonksiyonlar; test/reklam_karar_test.dart sınar.
//  - Premium kullanıcı hiçbir reklam görmez (SDK de başlatılmaz).
//  - Kontrol grubu banner ve geçiş reklamı görmez; ödüllü reklam isteğe bağlı olduğu için onlara da sunulur.
//  - Ödüllü reklamla günde en çok [gunlukOdulluSiniri] ek deneme açılır. Ek hak sınav BİTİNCE düşer;
//    önce o günün ücretsiz hakkı kullanılır (ucretsizHakDus mantığı değişmez).
import '../core/veri.dart';

enum ReklamTuru { banner, gecis, odullu }

/// Günde ödüllü reklamla açılabilecek en çok ek deneme.
const int gunlukOdulluSiniri = 3;

/// Sonuç ekranı çizildikten sonra geçiş reklamına kadar beklenen süre.
const Duration gecisGecikmesi = Duration(seconds: 1);

// ---- Remote Config anahtarları ve koddaki varsayılanları
const String rcBanner = 'reklam_banner_acik';
const String rcGecis = 'reklam_gecis_acik';
const String rcOdullu = 'reklam_odullu_acik';
const String rcKontrolOrani = 'kontrol_grubu_orani';

const Map<String, Object> uzakVarsayilan = {
  rcBanner: true,
  rcGecis: true,
  rcOdullu: true,
  rcKontrolOrani: 0.5,
};

/// Remote Config'te her reklam türünü açıp kapatan anahtar.
String uzakAnahtar(ReklamTuru t) => switch (t) {
      ReklamTuru.banner => rcBanner,
      ReklamTuru.gecis => rcGecis,
      ReklamTuru.odullu => rcOdullu,
    };

/// Reklam SDK'sı (ve UMP rıza formu) başlatılmalı mı. Premium'da asla.
bool reklamSdkGerekli({required bool premium}) => !premium;

/// Bu reklam türü bu kullanıcıya gösterilebilir mi.
/// [uzakAcik]: Remote Config anahtarı; [rizaTamam]: UMP canRequestAds; [kimlikVar]: birim kimliği seçilebildi.
bool reklamUygun(
  ReklamTuru t, {
  required bool premium,
  required bool kontrolGrubu,
  required bool uzakAcik,
  required bool rizaTamam,
  required bool kimlikVar,
}) {
  if (premium || !uzakAcik || !rizaTamam || !kimlikVar) return false;
  if (kontrolGrubu && t != ReklamTuru.odullu) return false;
  return true;
}

// ---- Kontrol grubu
/// İlk açılışta üretilen kalıcı [zar] (0–1), [oran]dan küçükse kullanıcı reklamsız kontrol grubundadır.
bool kontrolGrubunda(double zar, double oran) => zar < oran.clamp(0.0, 1.0);

/// Analytics user property `reklam_grubu` değeri.
String reklamGrubu(bool kontrol) => kontrol ? 'kontrol' : 'reklamli';

/// Kayıtlı zar geçerliyse onu, değilse yeni üretileni döndürür.
double zarSec(double? kayitli, double Function() uret) =>
    (kayitli != null && kayitli >= 0 && kayitli < 1) ? kayitli : uret();

// ---- Ödüllü reklam ve ek deneme hakkı
/// Bugün ödüllü reklamla açılmış ek deneme sayısı ([tarih] başka günse 0).
int bugunkuOdullu({required String? tarih, required int sayi, required DateTime simdi}) =>
    tarih == gunAnahtari(simdi) ? sayi : 0;

/// Bugün ödüllü reklamla bir ek deneme daha açılabilir mi.
bool odulluHakKaldi({required String? tarih, required int sayi, required DateTime simdi}) =>
    bugunkuOdullu(tarih: tarih, sayi: sayi, simdi: simdi) < gunlukOdulluSiniri;

/// Ödül kazanılınca yeni (tarih, bugünkü sayı).
(String, int) odulluSay({required String? tarih, required int sayi, required DateTime simdi}) =>
    (gunAnahtari(simdi), bugunkuOdullu(tarih: tarih, sayi: sayi, simdi: simdi) + 1);

/// Premium olmadan yeni sınav başlatılabilir mi: ücretsiz hak veya ödüllü ek hak.
bool sinavHakkiVar({
  required int bitmis,
  required String? gunlukTarih,
  required int ekHak,
  required DateTime simdi,
}) =>
    ucretsizSinavVar(bitmis: bitmis, gunlukTarih: gunlukTarih, simdi: simdi) || ekHak > 0;

class HakDurumu {
  final int bitmis;
  final String? gunlukTarih;
  final int ekHak;
  const HakDurumu(this.bitmis, this.gunlukTarih, this.ekHak);
}

/// Premium olmadan biten sınavın düşürdüğü hak. [baslangic]: sınavın başladığı an.
/// O gün için ücretsiz hak varsa o düşer (ucretsizHakDus); yoksa bir ek hak düşer.
HakDurumu sinavHakDus({
  required int bitmis,
  required String? gunlukTarih,
  required int ekHak,
  required DateTime baslangic,
}) {
  if (ekHak > 0 && !ucretsizSinavVar(bitmis: bitmis, gunlukTarih: gunlukTarih, simdi: baslangic)) {
    return HakDurumu(bitmis, gunlukTarih, ekHak - 1);
  }
  final (b, g) = ucretsizHakDus(bitmis: bitmis, gunlukTarih: gunlukTarih, simdi: baslangic);
  return HakDurumu(b, g, ekHak < 0 ? 0 : ekHak);
}

// ---- Reklam birimi kimliği
/// [test] ise test kimliği; değilse gerçek kimlik, o da boşsa null (reklam yüklenmez).
String? kimlikSec({required bool test, required String testKimlik, required String gercek}) {
  if (test) return testKimlik;
  final g = gercek.trim();
  return g.isEmpty ? null : g;
}

/// Release'de reklam yalnızca hem uygulama kimliği hem birim kimliği girilmişse istenir.
String? birimSec({
  required bool test,
  required String uygulama,
  required String testBirim,
  required String gercekBirim,
}) {
  if (test) return testBirim;
  if (uygulama.trim().isEmpty) return null;
  return kimlikSec(test: false, testKimlik: testBirim, gercek: gercekBirim);
}

// ---- Analytics rızası (Consent Mode v2)
// Manifestte dört ayar varsayılan olarak false (denied). UMP sonucu okunduktan sonra burada karar verilir.

/// UMP ConsentStatus'un eklentiden bağımsız hâli.
enum RizaDurumu { bilinmiyor, gerekli, gerekmiyor, alindi }

class AnalyticsRizasi {
  final bool analyticsStorage, adStorage, adUserData, adPersonalization;
  const AnalyticsRizasi({
    this.analyticsStorage = false,
    this.adStorage = false,
    this.adUserData = false,
    this.adPersonalization = false,
  });

  static const AnalyticsRizasi hepsiRed = AnalyticsRizasi();
  static const AnalyticsRizasi hepsiOnay =
      AnalyticsRizasi(analyticsStorage: true, adStorage: true, adUserData: true, adPersonalization: true);

  @override
  bool operator ==(Object o) =>
      o is AnalyticsRizasi &&
      o.analyticsStorage == analyticsStorage &&
      o.adStorage == adStorage &&
      o.adUserData == adUserData &&
      o.adPersonalization == adPersonalization;

  @override
  int get hashCode => Object.hash(analyticsStorage, adStorage, adUserData, adPersonalization);

  @override
  String toString() =>
      'AnalyticsRizasi(analytics: $analyticsStorage, adStorage: $adStorage, adUserData: $adUserData, adPers: $adPersonalization)';
}

/// IAB TCF `IABTCF_PurposeConsents` dizisinde [no]. amaç (1'den başlar) onaylı mı ('1').
bool tcfAmacOnayli(String? amaclar, int no) =>
    amaclar != null && no >= 1 && amaclar.length >= no && amaclar[no - 1] == '1';

/// UMP sonucuna göre Analytics rızası.
///  - Rıza gerekmiyor (AEA dışı): hepsi granted. Premium'da yalnızca analytics_storage (reklam yok).
///  - Rıza alındı: TCF amaçları — 1: analytics_storage + ad_storage, 3 ve 4: ad_personalization, 7: ad_user_data.
///  - Gerekli ama alınmadı veya bilinmiyor (bölge bilinmiyor): hepsi denied.
AnalyticsRizasi analyticsRizasi({
  required RizaDurumu durum,
  required String? tcfAmaclar,
  required bool premium,
}) {
  switch (durum) {
    case RizaDurumu.gerekmiyor:
      return premium ? const AnalyticsRizasi(analyticsStorage: true) : AnalyticsRizasi.hepsiOnay;
    case RizaDurumu.alindi:
      final a1 = tcfAmacOnayli(tcfAmaclar, 1);
      return AnalyticsRizasi(
        analyticsStorage: a1,
        adStorage: a1,
        adPersonalization: tcfAmacOnayli(tcfAmaclar, 3) && tcfAmacOnayli(tcfAmaclar, 4),
        adUserData: tcfAmacOnayli(tcfAmaclar, 7),
      );
    case RizaDurumu.gerekli:
    case RizaDurumu.bilinmiyor:
      return AnalyticsRizasi.hepsiRed;
  }
}
