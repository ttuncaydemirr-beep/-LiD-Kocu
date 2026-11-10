import 'package:flutter_test/flutter_test.dart';
import 'package:lid_kocu/services/billing_karar.dart';

const _id = 'premium';

void main() {
  group('ozetle + satinAlmaSonucu', () {
    test('odenmis satin alma: alindi', () {
      final o = ozetle(const [AlimKaydi(_id, AlimDurumu.alindi)], _id);
      expect(o.alindi, isTrue);
      expect(o.geriYukleme, isFalse);
      expect(satinAlmaSonucu(o), SatinAlmaSonucu.alindi);
    });

    test('bekleyen odeme: bekliyor, hak verilmez', () {
      final o = ozetle(const [AlimKaydi(_id, AlimDurumu.bekliyor, gercek: false)], _id);
      expect(o.alindi, isFalse);
      expect(satinAlmaSonucu(o), SatinAlmaSonucu.bekliyor);
    });

    test('purchased durumunda ama Play durumu PENDING: bekliyor', () {
      final o = ozetle(const [AlimKaydi(_id, AlimDurumu.alindi, gercek: false)], _id);
      expect(o.alindi, isFalse);
      expect(satinAlmaSonucu(o), SatinAlmaSonucu.bekliyor);
    });

    test('iptal bos urun kimligiyle gelir: sessiz iptal, hata degil', () {
      final o = ozetle(const [AlimKaydi('', AlimDurumu.iptal)], _id);
      expect(satinAlmaSonucu(o), SatinAlmaSonucu.iptal);
    });

    test('hata bos urun kimligiyle: hata', () {
      final o = ozetle(const [AlimKaydi('', AlimDurumu.hata)], _id);
      expect(satinAlmaSonucu(o), SatinAlmaSonucu.hata);
    });

    test('baska urun Premium vermez', () {
      final o = ozetle(const [AlimKaydi('baska', AlimDurumu.alindi)], _id);
      expect(o.alindi, isFalse);
      expect(satinAlmaSonucu(o), SatinAlmaSonucu.hata);
    });

    test('bekleyen sonra odenen ayni listede: alindi kazanir', () {
      final o = ozetle(const [
        AlimKaydi(_id, AlimDurumu.bekliyor, gercek: false),
        AlimKaydi(_id, AlimDurumu.alindi),
      ], _id);
      expect(o.alindi, isTrue);
      expect(o.bekliyor, isFalse);
    });
  });

  group('geriYuklemeKarari', () {
    test('bos liste geri yukleme yanitidir', () {
      expect(ozetle(const [], _id).geriYukleme, isTrue);
    });

    test('sahip: true', () {
      final o = ozetle(const [AlimKaydi(_id, AlimDurumu.geriYuklendi)], _id);
      expect(o.geriYukleme, isTrue);
      expect(geriYuklemeKarari(o, agDogrulandi: false, eskiIstek: false), isTrue);
    });

    test('bos yanit + Play erisildi: Premium kapanir (iade)', () {
      final o = ozetle(const [], _id);
      expect(geriYuklemeKarari(o, agDogrulandi: true, eskiIstek: false), isFalse);
    });

    test('bos yanit + cevrimdisi: kayitli deger korunur', () {
      final o = ozetle(const [], _id);
      expect(geriYuklemeKarari(o, agDogrulandi: false, eskiIstek: false), isNull);
    });

    test('satin almadan once gonderilmis eski bos yanit: degismez', () {
      final o = ozetle(const [], _id);
      expect(geriYuklemeKarari(o, agDogrulandi: true, eskiIstek: true), isNull);
    });

    test('geri yuklemede bekleyen odeme: degismez', () {
      final o = ozetle(const [AlimKaydi(_id, AlimDurumu.geriYuklendi, gercek: false)], _id);
      expect(o.bekliyor, isTrue);
      expect(geriYuklemeKarari(o, agDogrulandi: true, eskiIstek: false), isNull);
    });
  });

  group('tekrarla (onay yeniden deneme)', () {
    test('ucuncu denemede basarili', () async {
      var n = 0;
      final ok = await tekrarla(() async => ++n == 3, bekleme: (_) => Duration.zero);
      expect(ok, isTrue);
      expect(n, 3);
    });

    test('hep basarisiz: false, en fazla 3 deneme', () async {
      var n = 0;
      final ok = await tekrarla(() async {
        n++;
        return false;
      }, bekleme: (_) => Duration.zero);
      expect(ok, isFalse);
      expect(n, 3);
    });

    test('istisna basarisiz deneme sayilir', () async {
      var n = 0;
      final ok = await tekrarla(() async {
        n++;
        if (n == 1) throw StateError('ag yok');
        return true;
      }, bekleme: (_) => Duration.zero);
      expect(ok, isTrue);
      expect(n, 2);
    });
  });
}
