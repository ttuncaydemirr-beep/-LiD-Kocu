import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lid_kocu/services/billing_ayar.dart';
import 'package:lid_kocu/services/billing_karar.dart';
import 'package:lid_kocu/services/imza_dogrula.dart';
import 'package:pointycastle/export.dart';

Uint8List _der(int etiket, List<int> v) {
  final b = <int>[etiket];
  if (v.length < 128) {
    b.add(v.length);
  } else if (v.length < 256) {
    b.addAll([0x81, v.length]);
  } else {
    b.addAll([0x82, v.length >> 8, v.length & 0xff]);
  }
  return Uint8List.fromList([...b, ...v]);
}

List<int> _int(BigInt n) {
  var h = n.toRadixString(16);
  if (h.length.isOdd) h = '0$h';
  var b = [for (var i = 0; i < h.length; i += 2) int.parse(h.substring(i, i + 2), radix: 16)];
  if (b.first & 0x80 != 0) b = [0, ...b];
  return _der(0x02, b);
}

/// Play Console'daki "lisans anahtarı" biçimi: base64 X.509 SubjectPublicKeyInfo.
String _spki(RSAPublicKey k) {
  final algo = _der(0x30, [
    ..._der(0x06, [0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01]),
    0x05, 0x00,
  ]);
  final rsa = _der(0x30, [..._int(k.modulus!), ..._int(k.exponent!)]);
  final bit = _der(0x03, [0, ...rsa]);
  return base64.encode(_der(0x30, [...algo, ...bit]));
}

AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _anahtarUret(int tohum) {
  final rnd = FortunaRandom()..seed(KeyParameter(Uint8List.fromList(List.generate(32, (i) => (i * 7 + tohum) & 0xff))));
  final g = RSAKeyGenerator()
    ..init(ParametersWithRandom(RSAKeyGeneratorParameters(BigInt.from(65537), 1024, 64), rnd));
  final kp = g.generateKeyPair();
  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(kp.publicKey as RSAPublicKey, kp.privateKey as RSAPrivateKey);
}

String _imzala(RSAPrivateKey k, String veri) {
  final s = RSASigner(SHA256Digest(), '0609608648016503040201')..init(true, PrivateKeyParameter<RSAPrivateKey>(k));
  return base64.encode(s.generateSignature(Uint8List.fromList(utf8.encode(veri))).bytes);
}

const _json = '{"orderId":"GPA.1234-5678","packageName":"com.lidkocu.app","productId":"premium","purchaseState":0,'
    '"purchaseToken":"abc","acknowledged":false}';

void main() {
  final cift = _anahtarUret(1);
  final baska = _anahtarUret(2);
  final anahtar = _spki(cift.publicKey);
  final imza = _imzala(cift.privateKey, _json);

  group('satinAlmaImzasiniDogrula', () {
    test('dogru imza gecer', () {
      expect(satinAlmaImzasiniDogrula(lisansAnahtari: anahtar, imzaliVeri: _json, imza: imza), ImzaSonucu.gecerli);
    });

    test('PEM basligi ve satir sonlari olan anahtar da cozulur', () {
      final pem = '-----BEGIN PUBLIC KEY-----\n${anahtar.replaceAllMapped(RegExp('.{1,64}'), (m) => '${m[0]}\n')}-----END PUBLIC KEY-----';
      expect(satinAlmaImzasiniDogrula(lisansAnahtari: pem, imzaliVeri: _json, imza: imza), ImzaSonucu.gecerli);
    });

    test('bozuk imza reddedilir', () {
      final b = base64.decode(imza);
      b[10] ^= 0x01;
      expect(satinAlmaImzasiniDogrula(lisansAnahtari: anahtar, imzaliVeri: _json, imza: base64.encode(b)),
          ImzaSonucu.gecersiz);
    });

    test('degistirilmis veri reddedilir', () {
      expect(satinAlmaImzasiniDogrula(lisansAnahtari: anahtar, imzaliVeri: _json.replaceFirst('"purchaseState":0', '"purchaseState":1'), imza: imza),
          ImzaSonucu.gecersiz);
    });

    test('baska anahtarla atilmis imza reddedilir', () {
      final sahte = _imzala(baska.privateKey, _json);
      expect(satinAlmaImzasiniDogrula(lisansAnahtari: anahtar, imzaliVeri: _json, imza: sahte), ImzaSonucu.gecersiz);
    });

    test('bos ve base64 olmayan imza reddedilir (istisna atmaz)', () {
      expect(satinAlmaImzasiniDogrula(lisansAnahtari: anahtar, imzaliVeri: _json, imza: ''), ImzaSonucu.gecersiz);
      expect(satinAlmaImzasiniDogrula(lisansAnahtari: anahtar, imzaliVeri: _json, imza: '%%%'), ImzaSonucu.gecersiz);
    });

    test('bos anahtar: atla', () {
      expect(satinAlmaImzasiniDogrula(lisansAnahtari: '', imzaliVeri: _json, imza: 'onemsiz'), ImzaSonucu.atla);
      expect(satinAlmaImzasiniDogrula(lisansAnahtari: '  \n', imzaliVeri: _json, imza: ''), ImzaSonucu.atla);
    });

    test('cozulemeyen dolu anahtar: gecersiz (sessizce atlanmaz)', () {
      expect(satinAlmaImzasiniDogrula(lisansAnahtari: 'bozukanahtar', imzaliVeri: _json, imza: imza), ImzaSonucu.gecersiz);
    });
  });

  test('billing_ayar.dart: anahtar bos ya da cozulebilir (yanlis yapistirma CI\'da yakalanir)', () {
    if (playLisansAnahtari.isNotEmpty) {
      expect(genelAnahtarCoz(playLisansAnahtari), isNotNull);
    }
  });

  group('imzasi gecersiz kayit (billing_karar)', () {
    const id = 'premium';
    test('PURCHASED ama imza gecersiz: hak verilmez, bekliyor da sayilmaz', () {
      final o = ozetle(const [AlimKaydi(id, AlimDurumu.alindi, imzaGecerli: false)], id);
      expect(o.alindi, isFalse);
      expect(o.bekliyor, isFalse);
      expect(satinAlmaSonucu(o), SatinAlmaSonucu.hata);
    });

    test('restored ama imza gecersiz: geri yukleme, sahip degil', () {
      final o = ozetle(const [AlimKaydi(id, AlimDurumu.geriYuklendi, imzaGecerli: false)], id);
      expect(o.alindi, isFalse);
      expect(o.geriYukleme, isTrue);
      expect(geriYuklemeKarari(o, agDogrulandi: true, eskiIstek: false), isFalse);
    });

    test('gecerli kayit yanina sahte kayit gelse de gecerli olan sayilir', () {
      final o = ozetle(const [
        AlimKaydi(id, AlimDurumu.alindi, imzaGecerli: false),
        AlimKaydi(id, AlimDurumu.alindi),
      ], id);
      expect(o.alindi, isTrue);
    });

    test('varsayilan imzaGecerli true: onceki davranis ayni', () {
      expect(ozetle(const [AlimKaydi(id, AlimDurumu.alindi)], id).alindi, isTrue);
    });
  });
}
