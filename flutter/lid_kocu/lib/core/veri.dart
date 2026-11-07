// LiD Koçu — veri modeli ve sınav kuralları. Arayüzden bağımsızdır; test/veri_test.dart bu dosyayı sınar.
import 'dart:math';

const int genelSoruSayisi = 30;
const int eyaletSoruSayisi = 3;
const int sinavSoruSayisi = genelSoruSayisi + eyaletSoruSayisi;
const int gecmeNotu = 17;
const Duration sinavSuresi = Duration(minutes: 60);
const int ucretsizSinav = 2;

/// Cevabı zamanla değişebilen sorular.
const Set<String> guncelSorular = {'72', '73', '75', '236'};

class Soru {
  final String id;
  final String de;
  final List<String> secenekler;
  final int dogru;
  const Soru({required this.id, required this.de, required this.secenekler, required this.dogru});

  factory Soru.json(Map<String, dynamic> j) => Soru(
        id: j['id'].toString(),
        de: j['de'] as String,
        secenekler: (j['o'] as List).cast<String>(),
        dogru: j['c'] as int,
      );

  bool get guncel => guncelSorular.contains(id);
}

class Eyalet {
  final String ad;
  final List<Soru> sorular;
  const Eyalet(this.ad, this.sorular);
}

class Katalog {
  final String surum;
  final List<Soru> genel;
  final Map<String, Eyalet> eyaletler;
  const Katalog({required this.surum, required this.genel, required this.eyaletler});

  factory Katalog.json(Map<String, dynamic> j) {
    final Map<String, Eyalet> e = {};
    (j['states'] as Map<String, dynamic>).forEach((k, v) {
      final m = v as Map<String, dynamic>;
      e[k] = Eyalet(m['name'] as String,
          (m['q'] as List).map((x) => Soru.json(x as Map<String, dynamic>)).toList());
    });
    return Katalog(
      surum: j['stand'] as String,
      genel: (j['general'] as List).map((x) => Soru.json(x as Map<String, dynamic>)).toList(),
      eyaletler: e,
    );
  }

  List<Soru> havuz(String eyalet) => [...genel, ...?eyaletler[eyalet]?.sorular];

  /// Gerçek sınav biçimi: 30 genel + 3 eyalet sorusu, karışık sırada.
  List<Soru> sinavSec(String eyalet, [Random? r]) {
    final rng = r ?? Random();
    final g = [...genel]..shuffle(rng);
    final e = [...?eyaletler[eyalet]?.sorular]..shuffle(rng);
    return [...g.take(genelSoruSayisi), ...e.take(eyaletSoruSayisi)]..shuffle(rng);
  }
}

class Ceviri {
  final String soru;
  final List<String> secenekler;
  final List<String> gorsel;
  final String aciklama;
  const Ceviri(this.soru, this.secenekler, this.gorsel, this.aciklama);

  factory Ceviri.json(Map<String, dynamic> j) => Ceviri(
        (j['q'] ?? '') as String,
        ((j['o'] ?? const <dynamic>[]) as List).cast<String>(),
        ((j['g'] ?? const <dynamic>[]) as List).cast<String>(),
        (j['x'] ?? '') as String,
      );
}

/// Çeviriler: soru kimliği → dil → metin. Dosya yoksa boş kalır, uygulama Almanca çalışır.
class Ceviriler {
  final Map<String, dynamic> _ham;
  const Ceviriler(this._ham);

  Ceviri? al(String id, String dil) {
    final s = _ham[id];
    if (s is! Map<String, dynamic>) return null;
    final d = s[dil];
    return d is Map<String, dynamic> ? Ceviri.json(d) : null;
  }

  /// Resmî Almanca görsel açıklamaları.
  List<String> gorsel(String id) => al(id, 'de')?.gorsel ?? const [];
}

class Sinav {
  final List<Soru> sorular;
  final List<int?> cevaplar;
  final DateTime bitis;
  int sira = 0;
  bool bitti = false;

  Sinav(this.sorular, DateTime baslangic)
      : cevaplar = List<int?>.filled(sorular.length, null),
        bitis = baslangic.add(sinavSuresi);

  int get puan {
    var n = 0;
    for (var i = 0; i < sorular.length; i++) {
      if (cevaplar[i] == sorular[i].dogru) n++;
    }
    return n;
  }

  bool get gecti => puan >= gecmeNotu;
  int get bos => cevaplar.where((c) => c == null).length;
}

/// Ücretsiz örnek açıklamalar: ilk 20 genel soru.
bool ornekAciklama(String id) {
  final n = int.tryParse(id);
  return n != null && n <= 20;
}
