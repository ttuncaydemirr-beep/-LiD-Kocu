// Reklam kararları (lib/services/reklam_karar.dart) ve AppState'teki ek deneme hakkı.
import 'package:flutter_test/flutter_test.dart';
import 'package:lid_kocu/core/veri.dart';
import 'package:lid_kocu/services/reklam_karar.dart';
import 'package:lid_kocu/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool _uygun(
  ReklamTuru t, {
  bool premium = false,
  bool kontrol = false,
  bool uzak = true,
  bool riza = true,
  bool kimlik = true,
}) =>
    reklamUygun(t, premium: premium, kontrolGrubu: kontrol, uzakAcik: uzak, rizaTamam: riza, kimlikVar: kimlik);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final gun1 = DateTime(2026, 11, 11, 10);
  final gun2 = DateTime(2026, 11, 12, 9);

  group('reklam uygunlugu', () {
    test('premium hicbir reklam gormez, SDK baslatilmaz', () {
      for (final t in ReklamTuru.values) {
        expect(_uygun(t, premium: true), isFalse);
      }
      expect(reklamSdkGerekli(premium: true), isFalse);
      expect(reklamSdkGerekli(premium: false), isTrue);
    });

    test('ucretsiz reklamli grup her turu gorur', () {
      for (final t in ReklamTuru.values) {
        expect(_uygun(t), isTrue);
      }
    });

    test('kontrol grubu banner ve gecis gormez, odullu secenegi gorur', () {
      expect(_uygun(ReklamTuru.banner, kontrol: true), isFalse);
      expect(_uygun(ReklamTuru.gecis, kontrol: true), isFalse);
      expect(_uygun(ReklamTuru.odullu, kontrol: true), isTrue);
    });

    test('Remote Config kapaliysa, riza yoksa veya kimlik yoksa reklam yok', () {
      for (final t in ReklamTuru.values) {
        expect(_uygun(t, uzak: false), isFalse);
        expect(_uygun(t, riza: false), isFalse);
        expect(_uygun(t, kimlik: false), isFalse);
      }
    });

    test('Remote Config anahtarlari ve varsayilanlar', () {
      expect(uzakAnahtar(ReklamTuru.banner), 'reklam_banner_acik');
      expect(uzakAnahtar(ReklamTuru.gecis), 'reklam_gecis_acik');
      expect(uzakAnahtar(ReklamTuru.odullu), 'reklam_odullu_acik');
      expect(uzakVarsayilan, {
        'reklam_banner_acik': true,
        'reklam_gecis_acik': true,
        'reklam_odullu_acik': true,
        'kontrol_grubu_orani': 0.5,
      });
    });
  });

  group('kontrol grubu', () {
    test('zar orandan kucukse kontrol', () {
      expect(kontrolGrubunda(0.2, 0.5), isTrue);
      expect(kontrolGrubunda(0.5, 0.5), isFalse);
      expect(kontrolGrubunda(0.9, 0.5), isFalse);
      expect(kontrolGrubunda(0.0, 0.0), isFalse); // oran 0: herkes reklamli
      expect(kontrolGrubunda(0.99, 1.0), isTrue); // oran 1: herkes kontrol
      expect(kontrolGrubunda(0.3, -1), isFalse);
      expect(kontrolGrubunda(0.3, 7), isTrue);
    });

    test('grup adi', () {
      expect(reklamGrubu(true), 'kontrol');
      expect(reklamGrubu(false), 'reklamli');
    });

    test('kayitli zar korunur, gecersizse yenisi uretilir', () {
      expect(zarSec(0.42, () => 0.9), 0.42);
      expect(zarSec(null, () => 0.9), 0.9);
      expect(zarSec(1.5, () => 0.1), 0.1);
      expect(zarSec(-0.1, () => 0.1), 0.1);
    });
  });

  group('odullu ek hak', () {
    test('gunde en fazla 3; ertesi gun sifirlanir', () {
      String? tarih;
      var sayi = 0;
      for (var i = 0; i < gunlukOdulluSiniri; i++) {
        expect(odulluHakKaldi(tarih: tarih, sayi: sayi, simdi: gun1), isTrue);
        (tarih, sayi) = odulluSay(tarih: tarih, sayi: sayi, simdi: gun1);
      }
      expect(sayi, 3);
      expect(odulluHakKaldi(tarih: tarih, sayi: sayi, simdi: gun1), isFalse);
      expect(bugunkuOdullu(tarih: tarih, sayi: sayi, simdi: gun2), 0);
      expect(odulluHakKaldi(tarih: tarih, sayi: sayi, simdi: gun2), isTrue);
      expect(odulluSay(tarih: tarih, sayi: sayi, simdi: gun2), (gunAnahtari(gun2), 1));
    });

    test('ek hak varken sinav baslatilabilir', () {
      final bugun = gunAnahtari(gun1);
      expect(sinavHakkiVar(bitmis: 2, gunlukTarih: bugun, ekHak: 0, simdi: gun1), isFalse);
      expect(sinavHakkiVar(bitmis: 2, gunlukTarih: bugun, ekHak: 1, simdi: gun1), isTrue);
    });

    test('once ucretsiz hak duser, ek hak korunur', () {
      final h = sinavHakDus(bitmis: 0, gunlukTarih: null, ekHak: 2, baslangic: gun1);
      expect((h.bitmis, h.gunlukTarih, h.ekHak), (1, null, 2));
      final g = sinavHakDus(bitmis: 2, gunlukTarih: '2026-11-10', ekHak: 1, baslangic: gun1);
      expect((g.bitmis, g.gunlukTarih, g.ekHak), (2, gunAnahtari(gun1), 1));
    });

    test('ucretsiz hak yoksa ek hak duser; ucretsizHakDus mantigi degismez', () {
      final bugun = gunAnahtari(gun1);
      final h = sinavHakDus(bitmis: 2, gunlukTarih: bugun, ekHak: 2, baslangic: gun1);
      expect((h.bitmis, h.gunlukTarih, h.ekHak), (2, bugun, 1));
      // Ek hak yokken eski davranış: ucretsizHakDus ile aynı.
      for (final (b, g) in <(int, String?)>[(0, null), (1, null), (2, '2026-11-10'), (2, bugun)]) {
        final eski = ucretsizHakDus(bitmis: b, gunlukTarih: g, simdi: gun1);
        final yeni = sinavHakDus(bitmis: b, gunlukTarih: g, ekHak: 0, baslangic: gun1);
        expect((yeni.bitmis, yeni.gunlukTarih, yeni.ekHak), (eski.$1, eski.$2, 0));
      }
    });
  });

  group('analytics rizasi (Consent Mode v2)', () {
    const ret = AnalyticsRizasi.hepsiRed;
    const onay = AnalyticsRizasi.hepsiOnay;

    test('riza gerekmiyorsa hepsi granted', () {
      expect(analyticsRizasi(durum: RizaDurumu.gerekmiyor, tcfAmaclar: null, premium: false), onay);
    });

    test('riza gerekli/bilinmiyor ise hepsi denied', () {
      for (final p in [false, true]) {
        expect(analyticsRizasi(durum: RizaDurumu.gerekli, tcfAmaclar: '1111111111', premium: p), ret);
        expect(analyticsRizasi(durum: RizaDurumu.bilinmiyor, tcfAmaclar: '1111111111', premium: p), ret);
      }
    });

    test('riza alindi: TCF amaclari 1, 3+4, 7', () {
      expect(analyticsRizasi(durum: RizaDurumu.alindi, tcfAmaclar: '1111111111', premium: false), onay);
      expect(analyticsRizasi(durum: RizaDurumu.alindi, tcfAmaclar: '0000000000', premium: false), ret);
      expect(analyticsRizasi(durum: RizaDurumu.alindi, tcfAmaclar: null, premium: false), ret);
      expect(analyticsRizasi(durum: RizaDurumu.alindi, tcfAmaclar: '', premium: false), ret);
      expect(
        analyticsRizasi(durum: RizaDurumu.alindi, tcfAmaclar: '1000000000', premium: false),
        const AnalyticsRizasi(analyticsStorage: true, adStorage: true),
      );
      // 3 var, 4 yok: ad_personalization denied; 7 var: ad_user_data granted.
      expect(
        analyticsRizasi(durum: RizaDurumu.alindi, tcfAmaclar: '0010001000', premium: false),
        const AnalyticsRizasi(adUserData: true),
      );
      expect(
        analyticsRizasi(durum: RizaDurumu.alindi, tcfAmaclar: '0011000', premium: false),
        const AnalyticsRizasi(adPersonalization: true),
      );
      // Kısa dizi: eksik amaç denied.
      expect(
        analyticsRizasi(durum: RizaDurumu.alindi, tcfAmaclar: '1111', premium: false),
        const AnalyticsRizasi(analyticsStorage: true, adStorage: true, adPersonalization: true),
      );
    });

    test('premium: AEA disinda yalniz analytics_storage, daha once riza alindiysa TCF', () {
      expect(
        analyticsRizasi(durum: RizaDurumu.gerekmiyor, tcfAmaclar: null, premium: true),
        const AnalyticsRizasi(analyticsStorage: true),
      );
      expect(analyticsRizasi(durum: RizaDurumu.alindi, tcfAmaclar: '1111111111', premium: true), onay);
    });

    test('tcf amac okuma', () {
      expect(tcfAmacOnayli('101', 1), isTrue);
      expect(tcfAmacOnayli('101', 2), isFalse);
      expect(tcfAmacOnayli('101', 4), isFalse);
      expect(tcfAmacOnayli('101', 0), isFalse);
      expect(tcfAmacOnayli(null, 1), isFalse);
    });
  });

  group('reklam birimi kimligi', () {
    test('test derlemesinde test kimligi', () {
      expect(birimSec(test: true, uygulama: '', testBirim: 'T', gercekBirim: ''), 'T');
      expect(birimSec(test: true, uygulama: 'app', testBirim: 'T', gercekBirim: 'G'), 'T');
    });

    test('release: gercek kimlik bossa reklam yuklenmez', () {
      expect(birimSec(test: false, uygulama: '', testBirim: 'T', gercekBirim: 'G'), isNull);
      expect(birimSec(test: false, uygulama: 'app', testBirim: 'T', gercekBirim: ''), isNull);
      expect(birimSec(test: false, uygulama: 'app', testBirim: 'T', gercekBirim: '  '), isNull);
      expect(birimSec(test: false, uygulama: 'app', testBirim: 'T', gercekBirim: ' G '), 'G');
      expect(kimlikSec(test: false, testKimlik: 'T', gercek: ''), isNull);
    });
  });

  group('AppState ek hak ve gecis reklami', () {
    Future<AppState> yeni(Map<String, Object> ilk) async {
      SharedPreferences.setMockInitialValues({'kurulum': true, ...ilk});
      return AppState.olustur(sesli: false);
    }

    test('ucretsiz hak bitince ek hakla sinav acilir ve bitince duser (kalici)', () async {
      final s = await yeni({'sinavSayisi': 2, 'gunlukTarih': gunAnahtari(gun1), 'ekHak': 1});
      s.saat = () => gun1;
      expect(s.ucretsizKalanSinav, 0);
      expect(s.ekHakKalan, 1);
      expect(s.sinavAcik, isTrue);
      expect(s.sinavBaslat(), isTrue);
      expect(s.ekHak, 1, reason: 'hak sinav bitince duser');
      s.sinavBitir();
      expect(s.ekHak, 0);
      expect(s.sinavAcik, isFalse);
      final s2 = await AppState.olustur(sesli: false);
      s2.saat = () => gun1;
      expect(s2.ekHak, 0);
      expect(s2.sinavAcik, isFalse);
    });

    test('gunun ucretsiz hakki varken ek hak harcanmaz', () async {
      final s = await yeni({'sinavSayisi': 2, 'gunlukTarih': '2026-11-10', 'ekHak': 2});
      s.saat = () => gun1;
      expect(s.sinavBaslat(), isTrue);
      s.sinavBitir();
      expect(s.ekHak, 2);
      expect(s.gunlukTarih, gunAnahtari(gun1));
    });

    test('biten sinav bir kez gecis reklami bekler; reklam kapaliyken sessizce atlanir', () async {
      final s = await yeni({});
      s.saat = () => gun1;
      expect(s.sinavBaslat(), isTrue);
      final x = s.sinav!;
      expect(s.gecisBekliyor(x), isFalse, reason: 'sinav sirasinda gecis reklami yok');
      s.sinavBitir();
      expect(s.gecisBekliyor(x), isTrue);
      expect(s.reklam.etkin, isFalse, reason: 'testte reklam SDK baslatilmaz');
      s.sonucGosterildi(x);
      expect(s.gecisBekliyor(x), isFalse);
    });

    test('acilista biten sinav icin gecis reklami istenmez', () async {
      final eski = DateTime.now().subtract(const Duration(hours: 3));
      final s1 = await yeni({});
      s1.saat = () => eski;
      expect(s1.sinavBaslat(), isTrue);
      s1.sinavCevap(1);
      final s2 = await AppState.olustur(sesli: false); // kapalıyken süresi doldu
      expect(s2.sinav?.bitti, isTrue);
      expect(s2.gecisBekliyor(s2.sinav!), isFalse);
    });

    test('kontrol grubu kalici zarla belirlenir', () async {
      final a = await yeni({'reklamZar': 0.1});
      expect(a.reklamZar, 0.1);
      expect(a.kontrolGrubu, isTrue);
      final b = await yeni({'reklamZar': 0.8});
      expect(b.kontrolGrubu, isFalse);
      final c = await yeni({});
      final ilk = c.reklamZar;
      expect(ilk >= 0 && ilk < 1, isTrue);
      final c2 = await AppState.olustur(sesli: false);
      expect(c2.reklamZar, ilk);
    });

    test('premium: odullu teklif yok, ek hak sayilmaz', () async {
      final s = await yeni({'premium': true, 'ekHak': 2});
      expect(s.ekHakKalan, 0);
      expect(s.odulluSunulur, isFalse);
      expect(s.reklam.bannerAlani, isFalse);
    });
  });
}
