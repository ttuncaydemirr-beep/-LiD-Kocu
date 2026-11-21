// LiD Koçu — Google Play satın alma imzasının yerelde doğrulanması (saf Dart, platform kanalı yok).
// Play, her satın alma için JSON metnini (originalJson) lisans anahtarının özel eşiyle SHA256withRSA
// (PKCS#1 v1.5) imzalar; imza base64'tür. Burada genel anahtarla doğrulanır. test/imza_dogrula_test.dart sınar.
import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

enum ImzaSonucu {
  /// Anahtar boş: doğrulama yapılmadı, mevcut davranış sürer.
  atla,
  gecerli,

  /// İmza tutmuyor ya da anahtar/imza çözülemedi: kayıt gerçek sayılmaz.
  gecersiz,
}

/// [lisansAnahtari]: Play Console'daki base64 X.509 SubjectPublicKeyInfo (RSA). Boşsa [ImzaSonucu.atla].
/// [imzaliVeri]: originalJson (olduğu gibi, bayt bayt). [imza]: base64 imza.
ImzaSonucu satinAlmaImzasiniDogrula({
  required String lisansAnahtari,
  required String imzaliVeri,
  required String imza,
}) {
  if (lisansAnahtari.trim().isEmpty) return ImzaSonucu.atla;
  try {
    final anahtar = genelAnahtarCoz(lisansAnahtari);
    if (anahtar == null || imza.trim().isEmpty) return ImzaSonucu.gecersiz;
    final imzaBaytlari = base64.decode(base64.normalize(imza.replaceAll(RegExp(r'\s'), '')));
    // SHA-256 DigestInfo OID'si (2.16.840.1.101.3.4.2.1).
    final dogrulayici = RSASigner(SHA256Digest(), '0609608648016503040201')
      ..init(false, PublicKeyParameter<RSAPublicKey>(anahtar));
    final ok = dogrulayici.verifySignature(
      Uint8List.fromList(utf8.encode(imzaliVeri)),
      RSASignature(Uint8List.fromList(imzaBaytlari)),
    );
    return ok ? ImzaSonucu.gecerli : ImzaSonucu.gecersiz;
  } catch (_) {
    return ImzaSonucu.gecersiz;
  }
}

/// base64 X.509 SubjectPublicKeyInfo → RSA genel anahtarı; çözülemezse null.
RSAPublicKey? genelAnahtarCoz(String b64) {
  try {
    final temiz = b64
        .replaceAll(RegExp(r'-----[^-]+-----'), '')
        .replaceAll(RegExp(r'\s'), '');
    final der = base64.decode(base64.normalize(temiz));
    final spki = _Okuyucu(der).dizi(); // SEQUENCE { algorithm, BIT STRING }
    final algoritma = spki.dizi(); // SEQUENCE { OID, NULL }
    final oid = algoritma.oku(0x06);
    // rsaEncryption 1.2.840.113549.1.1.1
    const rsaOid = [0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01];
    if (oid.length != rsaOid.length) return null;
    for (var i = 0; i < rsaOid.length; i++) {
      if (oid[i] != rsaOid[i]) return null;
    }
    final bit = spki.oku(0x03);
    if (bit.isEmpty || bit[0] != 0) return null; // kullanılmayan bit yok
    final rsa = _Okuyucu(Uint8List.fromList(bit.sublist(1))).dizi(); // SEQUENCE { n, e }
    final n = _tamsayi(rsa.oku(0x02));
    final e = _tamsayi(rsa.oku(0x02));
    if (n.bitLength < 512 || e <= BigInt.one) return null;
    return RSAPublicKey(n, e);
  } catch (_) {
    return null;
  }
}

BigInt _tamsayi(List<int> b) {
  var r = BigInt.zero;
  for (final x in b) {
    r = (r << 8) | BigInt.from(x);
  }
  return r;
}

/// En küçük DER okuyucu: etiket + uzunluk + değer.
class _Okuyucu {
  _Okuyucu(this._b);
  final Uint8List _b;
  int _i = 0;

  List<int> oku(int etiket) {
    if (_i >= _b.length || _b[_i++] != etiket) throw const FormatException('DER etiketi');
    var uzunluk = _b[_i++];
    if (uzunluk & 0x80 != 0) {
      final n = uzunluk & 0x7f;
      if (n == 0 || n > 4) throw const FormatException('DER uzunluğu');
      uzunluk = 0;
      for (var k = 0; k < n; k++) {
        uzunluk = (uzunluk << 8) | _b[_i++];
      }
    }
    if (_i + uzunluk > _b.length) throw const FormatException('DER taşması');
    final v = _b.sublist(_i, _i + uzunluk);
    _i += uzunluk;
    return v;
  }

  _Okuyucu dizi() => _Okuyucu(Uint8List.fromList(oku(0x30)));
}
