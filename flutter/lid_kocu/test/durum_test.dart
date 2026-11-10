// AppState kuralları: ücretsiz sınav sınırı, devam eden sınavın korunması/kaydı, süre dolması, çalışma konumu.
import 'package:flutter_test/flutter_test.dart';
import 'package:lid_kocu/core/veri.dart';
import 'package:lid_kocu/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _yeni([Map<String, Object> ilk = const {'kurulum': true}]) async {
  SharedPreferences.setMockInitialValues(ilk);
  return AppState.olustur(sesli: false);
}

/// Aynı (mock) tercihlerle uygulamayı yeniden açar.
Future<AppState> _yenidenAc() => AppState.olustur(sesli: false);

void _bitir(AppState s) {
  expect(s.sinavBaslat(), isTrue);
  s.sinavBitir();
  expect(s.sinav!.bitti, isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final gun1 = DateTime(2026, 11, 11, 10);

  group('ucretsiz sinav siniri', () {
    test('2 baslangic + her gun 1; hak bitirince duser', () async {
      final s = await _yeni();
      s.saat = () => gun1;
      expect(s.ucretsizKalanSinav, 2);
      _bitir(s);
      expect(s.ucretsizKalanSinav, 1);
      _bitir(s);
      expect(s.ucretsizKalanSinav, 0);
      expect(s.sinavAcik, isFalse);
      expect(s.sinavBaslat(), isFalse);

      s.saat = () => gun1.add(const Duration(days: 1));
      expect(s.sinavAcik, isTrue);
      expect(s.ucretsizKalanSinav, 1);
      _bitir(s);
      expect(s.sinavAcik, isFalse);

      s.saat = () => gun1.add(const Duration(days: 2));
      expect(s.sinavAcik, isTrue);
    });

    test('yarida birakilan sinav hak yemez; ikinci baslat ayni sinava devam eder', () async {
      final s = await _yeni();
      s.saat = () => gun1;
      expect(s.sinavBaslat(), isTrue);
      final ilk = s.sinav;
      s.sinavCevap(1);
      expect(s.sinavSayisi, 0);
      expect(s.ucretsizKalanSinav, 2);
      expect(s.sinavBaslat(), isTrue);
      expect(identical(s.sinav, ilk), isTrue);
      expect(s.sinav!.cevaplar.first, 1);
    });

    test('sinir yeniden acilista korunur', () async {
      final s = await _yeni();
      s.saat = () => gun1;
      _bitir(s);
      _bitir(s);
      final s2 = await _yenidenAc();
      s2.saat = () => gun1;
      expect(s2.sinavAcik, isFalse);
      expect(s2.gecmis.length, 2);
    });
  });

  group('devam eden sinav', () {
    test('kaydedilir ve yeniden acilinca geri yuklenir', () async {
      final s = await _yeni();
      s.sinavBaslat();
      s.sinavCevap(2);
      s.sinavCevap(3);
      final x = s.sinav!;
      final s2 = await _yenidenAc();
      final y = s2.sinav;
      expect(y, isNotNull);
      expect(y!.bitti, isFalse);
      expect([for (final q in y.sorular) q.id], [for (final q in x.sorular) q.id]);
      expect(y.cevaplar.take(3).toList(), [2, 3, null]);
      expect(y.sira, 2);
      expect(y.bitis.millisecondsSinceEpoch, x.bitis.millisecondsSinceEpoch);
      // Geri yüklenen sınavda yeni sınav açılmaz.
      expect(s2.sinavBaslat(), isTrue);
      expect(identical(s2.sinav, y), isTrue);
    });

    test('bitince kayit silinir', () async {
      final s = await _yeni();
      _bitir(s);
      final s2 = await _yenidenAc();
      expect(s2.sinav, isNull);
    });

    test('uygulama kapaliyken suresi dolan sinav acilista biter ve hak duser', () async {
      final s = await _yeni();
      s.saat = () => DateTime.now().subtract(const Duration(minutes: 61));
      s.sinavBaslat();
      s.sinavCevap(0);
      final s2 = await _yenidenAc();
      expect(s2.sinav!.bitti, isTrue);
      expect(s2.sinavSayisi, 1);
      expect(s2.gecmis.length, 1);
    });
  });

  group('sure', () {
    test('sure dolunca sinav biter (sekmeden bagimsiz), sonra cevap kabul edilmez', () async {
      final s = await _yeni();
      s.saat = () => gun1;
      s.sinavBaslat();
      s.sinavCevap(1);
      s.saat = () => gun1.add(sinavSuresi + const Duration(seconds: 1));
      s.sinavCevap(2); // kabul edilmemeli
      final x = s.sinav!;
      expect(x.bitti, isTrue);
      expect(x.cevaplar[1], isNull);
      expect(s.sinavSayisi, 1);
    });

    test('yalnizca erisimde de biter', () async {
      final s = await _yeni();
      s.saat = () => gun1;
      s.sinavBaslat();
      s.saat = () => gun1.add(sinavSuresi);
      expect(s.sinav!.bitti, isTrue);
      expect(s.sinavDevamEdiyor, isFalse);
    });
  });

  group('calisma', () {
    test('konum suzgec basina kaydedilir ve geri gelir', () async {
      final s = await _yeni();
      final l = s.calismaListesi(filtreTumu);
      s.calisKonumKaydet(filtreTumu, l[7].id);
      final s2 = await _yenidenAc();
      final l2 = s2.calismaListesi(filtreTumu);
      expect(s2.calisBaslangic(filtreTumu, l2), 7);
      expect(s2.calisBaslangic(filtreYanlis, s2.calismaListesi(filtreYanlis)), 0);
    });

    test('karisik sira kalici tohumla ayni kalir', () async {
      final s = await _yeni();
      s.karisikSec(true);
      final a = [for (final q in s.calismaListesi(filtreTumu)) q.id];
      final s2 = await _yenidenAc();
      final b = [for (final q in s2.calismaListesi(filtreTumu)) q.id];
      expect(s2.karisik, isTrue);
      expect(b, a);
      expect(a, isNot([for (final q in s.havuz) q.id]));
    });

    test('son sinavin yanlislari calisma listesine gelir', () async {
      final s = await _yeni();
      s.sinavBaslat();
      s.sinavBitir(); // hepsi boş: 33 yanlış
      s.sonSinavYanlisCalis();
      expect(s.calisFiltre, filtreSinav);
      expect(s.calismaListesi(filtreSinav).length, sinavSoruSayisi);
    });
  });

  group('aciklama ve hazirlik', () {
    test('gunun sorusunun aciklamasi her zaman ucretsiz', () async {
      final s = await _yeni();
      expect(s.premium, isFalse);
      expect(s.aciklamaAcik(s.gununSorusu), isTrue);
      final kilitli = s.katalog.genel.firstWhere((q) => !ornekAciklama(q.id) && q.id != s.gununSorusu.id);
      expect(s.aciklamaAcik(kilitli), isFalse);
      expect(s.aciklamaAcik(kilitli, ucretsiz: true), isTrue);
    });

    test('hazirlik: gecmis yokken dogru orani, sonra son 3 deneme ile', () async {
      final s = await _yeni();
      expect(s.hazirlik, 0);
      expect(s.son3Ortalama, isNull);
      _bitir(s); // 0 puan
      expect(s.son3Ortalama, 0);
      expect(s.gecmis.single.puan, 0);
    });
  });
}
