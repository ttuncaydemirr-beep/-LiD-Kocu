// LiD Koçu — uygulama durumu. Arayüz yalnızca bu sınıfla konuşur.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/veri.dart';
import 'services/billing.dart';

const List<String> diller = ['tr', 'en', 'de', 'ar'];
const String destekEposta = 'nilkaren.tuncay.demir@gmail.com';
const String kaynakUrl =
    'https://www.bamf.de/SharedDocs/Anlagen/DE/Integration/Einbuergerung/gesamtfragenkatalog-lebenindeutschland.pdf';
const String testMerkeziUrl = 'https://oet.bamf.de/ords/oetut/f?p=514:1:0';

/// Çalış sekmesi süzgeçleri.
const String filtreTumu = 'all';
const String filtreYanlis = 'wrongs';
const String filtreSinav = 'exam';

/// Sesli dinleme sonucu.
enum SesSonucu { tamam, kilitli, dilYok, hata }

class Metin {
  final Map<String, Map<String, String>> _m;
  Metin(this._m);

  factory Metin.json(Map<String, dynamic> j) => Metin(j.map(
      (k, v) => MapEntry(k, (v as Map<String, dynamic>).map((a, b) => MapEntry(a, b.toString())))));

  /// t('tr', 'learned', {'a': 3, 'b': 310}) → "3 / 310 soru doğru bildin"
  String t(String dil, String anahtar, [Map<String, Object> v = const {}]) {
    var s = _m[dil]?[anahtar] ?? _m['en']?[anahtar] ?? anahtar;
    v.forEach((k, x) => s = s.replaceAll('{$k}', '$x'));
    return s;
  }
}

class AppState extends ChangeNotifier {
  final Katalog katalog;
  final Ceviriler ceviriler;
  final Metin metin;
  final SharedPreferences? _p;
  final Billing billing;
  final FlutterTts? _tts;
  /// Kimliğe göre soru (kayıtlı sınav ve yanlış listeleri için).
  final Map<String, Soru> _soruIndeksi;
  Soru? soruBul(String id) => _soruIndeksi[id];

  /// Saat kaynağı. Testlerde değiştirilir (gün değişimi, süre dolması).
  @visibleForTesting
  DateTime Function() saat = DateTime.now;
  DateTime simdi() => saat();

  String dil;
  String eyalet;
  bool kurulumTamam;
  final Map<String, bool> sonuclar;

  /// Premium olmadan bitirilen başlangıç denemeleri (en çok [ucretsizSinav]).
  int sinavSayisi;

  /// Günlük ücretsiz denemenin son kullanıldığı gün (gunAnahtari).
  String? gunlukTarih;
  Sinav? _sinav;
  final List<SinavKaydi> gecmis;

  /// Son bitmiş denemenin yanlış/boş soruları ("Yanlışlarını çalış").
  List<Soru>? sonSinavYanlislari;

  // Çalış sekmesi
  String calisFiltre = filtreTumu;
  bool karisik;
  int karisikTohum;
  final Map<String, String> _calisKonum;

  /// Premium olmadan yanlış açıklaması ücretsiz açılan soruların kimlikleri (kalıcı, sıradan bağımsız).
  /// Bir kez açılan soru açık kalır; liste sırası, karışık sıra veya sekme değişimi bunu değiştirmez.
  final Set<String> _ucretsizAcilan = {};

  /// Çalış > Yanlışlarım listesinin ilk ziyareti yapıldı mı (ilk 3 soru o ziyarette sabitlenir).
  bool _yanlisZiyaret = false;

  bool _atildi = false;

  AppState._(this.katalog, this.ceviriler, this.metin, this._p, this.billing, this._tts, this._soruIndeksi,
      {required this.dil,
      required this.eyalet,
      required this.kurulumTamam,
      required this.sonuclar,
      required this.sinavSayisi,
      required this.gunlukTarih,
      required this.gecmis,
      required this.karisik,
      required this.karisikTohum,
      required Map<String, String> calisKonum})
      : _calisKonum = calisKonum {
    billing.degisti = (v) {
      _p?.setBool('premium', v);
      _bildir();
    };
  }

  /// Testlerde sesli: false verilir: ses ve Play Billing başlatılmaz.
  static Future<AppState> olustur({bool sesli = true}) async {
    final k = Katalog.json(jsonDecode(await rootBundle.loadString('assets/katalog.json')) as Map<String, dynamic>);
    final c = Ceviriler(jsonDecode(await rootBundle.loadString('assets/ceviriler.json')) as Map<String, dynamic>);
    final m = Metin.json(jsonDecode(await rootBundle.loadString('assets/metin.json')) as Map<String, dynamic>);
    SharedPreferences? p;
    try {
      p = await SharedPreferences.getInstance();
    } catch (_) {}
    final cihaz = PlatformDispatcher.instance.locale.languageCode;
    final dil = p?.getString('dil') ?? (diller.contains(cihaz) ? cihaz : 'en');

    T? oku<T>(String anahtar, T Function(Object? j) cevir) {
      try {
        final raw = p?.getString(anahtar);
        return raw == null ? null : cevir(jsonDecode(raw));
      } catch (_) {
        return null;
      }
    }

    final s = oku('sonuclar', (j) => (j as Map<String, dynamic>).map((a, b) => MapEntry(a, b == true))) ??
        <String, bool>{};
    final gecmis = oku('gecmis', (j) => (j as List).map(SinavKaydi.fromJson).whereType<SinavKaydi>().toList()) ?? <SinavKaydi>[];
    final konum = oku('calisKonum', (j) => (j as Map<String, dynamic>).map((a, b) => MapEntry(a, b.toString()))) ??
        <String, String>{};

    final indeks = <String, Soru>{
      for (final x in k.genel) x.id: x,
      for (final e in k.eyaletler.values)
        for (final x in e.sorular) x.id: x,
    };

    final b = Billing(sahip: p?.getBool('premium') ?? false);
    // Eski sürümden gelenler (ayar kaydı olan) kurulum ekranını görmez.
    final kurulum = p?.getBool('kurulum') ?? (p?.containsKey('eyalet') == true || p?.containsKey('sonuclar') == true);
    final st = AppState._(k, c, m, p, b, sesli ? FlutterTts() : null, indeks,
        dil: dil,
        eyalet: p?.getString('eyalet') ?? 'berlin',
        kurulumTamam: kurulum,
        sonuclar: s,
        sinavSayisi: p?.getInt('sinavSayisi') ?? 0,
        gunlukTarih: p?.getString('gunlukTarih'),
        gecmis: gecmis,
        karisik: p?.getBool('karisik') ?? false,
        karisikTohum: p?.getInt('karisikTohum') ?? 1,
        calisKonum: konum);
    final f = p?.getString('calisFiltre');
    if (f == filtreYanlis) st.calisFiltre = filtreYanlis;
    st._ucretsizAcilan.addAll(p?.getStringList('ucretsizAcilan') ?? const <String>[]);
    st._yanlisZiyaret = p?.getBool('yanlisZiyaret') ?? false;
    st._sinav = oku<Sinav?>('sinavDevam', (j) => Sinav.fromJson(j as Map<String, dynamic>, (id) => indeks[id]));
    st._sureKontrol(bildir: false); // kapalıyken süresi dolan sınav burada biter
    // Play bağlantısı ilk ekranı bekletmez.
    if (sesli) unawaited(b.baslat());
    return st;
  }

  void _bildir() {
    if (!_atildi) notifyListeners();
  }

  // ---- metin ve çeviri
  String t(String anahtar, [Map<String, Object> v = const {}]) => metin.t(dil, anahtar, v);
  bool get rtl => dil == 'ar';

  /// Seçili dildeki çeviri; dil Almanca ise null.
  Ceviri? ceviri(Soru s) => dil == 'de' ? null : ceviriler.al(s.id, dil);
  String? aciklama(Soru s) {
    final x = ceviriler.al(s.id, dil)?.aciklama;
    return (x == null || x.isEmpty) ? null : x;
  }

  List<String> gorselDe(Soru s) => ceviriler.gorsel(s.id);
  List<String> gorselCeviri(Soru s) => dil == 'de' ? const [] : (ceviriler.al(s.id, dil)?.gorsel ?? const []);

  // ---- premium
  bool get premium => billing.sahip;

  /// Premium olmadan açık açıklama: örnek sorular, günün sorusu, [ucretsiz] veya yanlış listesinde
  /// ücretsiz açılmış (kimliği kalıcı kümede olan) soru.
  bool ucretsizAciklama(Soru s, {bool ucretsiz = false}) =>
      ucretsiz || ornekAciklama(s.id) || s.id == gununSorusu.id || _ucretsizAcilan.contains(s.id);
  bool aciklamaAcik(Soru s, {bool ucretsiz = false}) => premium || ucretsizAciklama(s, ucretsiz: ucretsiz);

  /// Yanlış listelerinde bu sorunun açıklaması (ve sorusu) Premium olmadan açık mı. Karar kimliğe bağlıdır.
  bool yanlisUcretsiz(Soru s) => _ucretsizAcilan.contains(s.id);

  /// [liste]nin ilk [ucretsizYanlis] sorusunu kalıcı kümeye ekler (Premium'da hiçbir şey yapmaz).
  void _yanlisUcretsizAc(Iterable<Soru> liste) {
    if (premium) return;
    var degisti = false;
    for (final q in liste.take(ucretsizYanlis)) {
      if (_ucretsizAcilan.add(q.id)) degisti = true;
    }
    if (degisti) _p?.setStringList('ucretsizAcilan', _ucretsizAcilan.toList());
  }

  bool get sinavAcik =>
      premium || ucretsizSinavVar(bitmis: sinavSayisi, gunlukTarih: gunlukTarih, simdi: simdi());

  /// Bugün kalan ücretsiz deneme; Premium'da null.
  int? get ucretsizKalanSinav =>
      premium ? null : ucretsizKalan(bitmis: sinavSayisi, gunlukTarih: gunlukTarih, simdi: simdi());

  Future<SatinAlmaSonucu> satinAl() async {
    final r = await billing.satinAl();
    _bildir();
    return r;
  }

  Future<bool?> geriYukle() async {
    final r = await billing.geriYukle();
    _bildir();
    return r;
  }

  /// Uygulama ön plana döndü: süreyi denetle, satın almaları sessizce yenile.
  void onPlanaDondu() {
    sureKontrol();
    unawaited(billing.yenile());
  }

  // ---- ayarlar
  void dilSec(String d) {
    if (!diller.contains(d)) return;
    dil = d;
    _p?.setString('dil', d);
    _bildir();
  }

  void eyaletSec(String e) {
    if (!katalog.eyaletler.containsKey(e)) return;
    eyalet = e;
    _p?.setString('eyalet', e);
    _bildir();
  }

  /// İlk açılış akışının sonu (dil zaten dilSec ile kaydedildi).
  void kurulumuBitir(String e) {
    eyalet = katalog.eyaletler.containsKey(e) ? e : eyalet;
    kurulumTamam = true;
    _p?.setString('dil', dil);
    _p?.setString('eyalet', eyalet);
    _p?.setBool('kurulum', true);
    _bildir();
  }

  // ---- çalışma
  List<Soru> get havuz => katalog.havuz(eyalet);
  int get dogruSayisi => havuz.where((s) => sonuclar[s.id] == true).length;
  List<Soru> get yanlislar => havuz.where((s) => sonuclar[s.id] == false).toList();

  Soru get gununSorusu {
    final g = katalog.genel;
    final n = simdi();
    final gun = DateTime.utc(n.year, n.month, n.day).difference(DateTime.utc(2026)).inDays;
    return g[gun % g.length];
  }

  void cevapla(Soru s, int secim) {
    sonuclar[s.id] = secim == s.dogru;
    _kaydet();
    _bildir();
  }

  void _kaydet() => _p?.setString('sonuclar', jsonEncode(sonuclar));

  /// Süzgece göre çalışma listesi (karışık sıra seçiliyse kalıcı tohumla karıştırılır).
  List<Soru> calismaListesi(String filtre) {
    final l = switch (filtre) {
      filtreYanlis => yanlislar,
      filtreSinav => [...?sonSinavYanlislari],
      _ => havuz,
    };
    if (karisik && filtre != filtreSinav) l.shuffle(Random(karisikTohum));
    if (filtre == filtreYanlis && !_yanlisZiyaret && !premium && l.isNotEmpty) {
      // İlk ziyaret: listedeki ilk 3 soru kimlikle sabitlenir; sonra sıra değişse de başka soru açılmaz.
      _yanlisUcretsizAc(l);
      _yanlisZiyaret = true;
      _p?.setBool('yanlisZiyaret', true);
    }
    return l;
  }

  /// Süzgeçte kalınan sorunun sırası (kayıtlı soru listede yoksa 0).
  int calisBaslangic(String filtre, List<Soru> l) {
    final id = _calisKonum[filtre];
    if (id == null) return 0;
    final i = l.indexWhere((s) => s.id == id);
    return i < 0 ? 0 : i;
  }

  void calisKonumKaydet(String filtre, String soruId) {
    _calisKonum[filtre] = soruId;
    if (filtre != filtreSinav) _p?.setString('calisKonum', jsonEncode(_calisKonum));
  }

  void calisFiltreSec(String f) {
    if (f == filtreSinav && sonSinavYanlislari == null) return;
    calisFiltre = f;
    if (f != filtreSinav) _p?.setString('calisFiltre', f);
    _bildir();
  }

  void karisikSec(bool v) {
    karisik = v;
    if (v) karisikTohum = Random().nextInt(1 << 30) + 1;
    _p?.setBool('karisik', v);
    _p?.setInt('karisikTohum', karisikTohum);
    _bildir();
  }

  // ---- hazırlık göstergesi
  /// Son 3 bitmiş denemenin ortalama puanı; geçmiş yoksa null.
  double? get son3Ortalama {
    if (gecmis.isEmpty) return null;
    final son = gecmis.reversed.take(3).toList();
    return son.fold<int>(0, (a, k) => a + k.puan) / son.length;
  }

  /// Hazırlık yüzdesi: doğru bilinen soru oranı; deneme varsa son 3 deneme ortalamasıyla yarı yarıya.
  int get hazirlik {
    final h = havuz.length;
    final oran = h == 0 ? 0.0 : dogruSayisi / h;
    final o = son3Ortalama;
    final x = o == null ? oran : (oran + o / sinavSoruSayisi) / 2;
    return (x * 100).round().clamp(0, 100).toInt();
  }

  // ---- sınav
  /// Devam eden sınav. Süresi dolmuşsa okunurken biter (sekme açık olmasa da).
  Sinav? get sinav {
    if (_sureKontrol(bildir: false)) scheduleMicrotask(_bildir);
    return _sinav;
  }

  bool get sinavDevamEdiyor {
    final x = sinav;
    return x != null && !x.bitti;
  }

  /// Süre dolduysa sınavı bitirir. Bitirdiyse true.
  bool sureKontrol() => _sureKontrol(bildir: true);

  bool _sureKontrol({required bool bildir}) {
    final x = _sinav;
    if (x == null || x.bitti || !x.suresiDoldu(simdi())) return false;
    _bitir(x, sureDoldu: true);
    if (bildir) _bildir();
    return true;
  }

  /// Devam eden sınav varsa ona devam edilir (true). Yoksa hak varsa yeni sınav başlar.
  /// Hak yoksa false döner; arayüz Premium ekranını gösterir. Hak sınav BİTİNCE düşer;
  /// aynı anda en çok bir başlamış-bitmemiş sınav olabilir, böylece sınır atlatılamaz.
  bool sinavBaslat() {
    _sureKontrol(bildir: false);
    final x = _sinav;
    if (x != null && !x.bitti) {
      _bildir();
      return true;
    }
    if (!sinavAcik) {
      _bildir();
      return false;
    }
    _sinav = Sinav(katalog.sinavSec(eyalet), simdi());
    _sinavKaydet();
    unawaited(sesDurdur());
    _bildir();
    return true;
  }

  void sinavCevap(int secim) {
    if (_sureKontrol(bildir: true)) return; // süre dolduktan sonra cevap kabul edilmez
    final x = _sinav;
    if (x == null || x.bitti) return;
    x.cevaplar[x.sira] = secim;
    if (x.sira < x.sorular.length - 1) x.sira++;
    unawaited(sesDurdur());
    _sinavKaydet();
    _bildir();
  }

  void sinavGit(int i) {
    _sureKontrol(bildir: false);
    final x = _sinav;
    if (x == null || i < 0 || i >= x.sorular.length) return;
    x.sira = i;
    unawaited(sesDurdur());
    if (!x.bitti) _sinavKaydet();
    _bildir();
  }

  void sinavBitir() {
    final x = _sinav;
    if (x == null || x.bitti) return;
    _bitir(x);
    _bildir();
  }

  void _bitir(Sinav x, {bool sureDoldu = false}) {
    // Hiç cevap verilmeden süresi dolan sınav: hak düşer ama geçmişe ve açıklama hakkına yazılmaz.
    final bosSure = sureDoldu && x.cevaplar.every((c) => c == null);
    x.bitti = true;
    x.sira = 0;
    for (var i = 0; i < x.sorular.length; i++) {
      final c = x.cevaplar[i];
      if (c != null) sonuclar[x.sorular[i].id] = c == x.sorular[i].dogru;
    }
    _kaydet();
    if (!premium) {
      // Hak, sınavın BAŞLADIĞI güne yazılır (terk edilip sonra süresi dolan sınav bugünün hakkını yemez).
      final baslangic = x.bitis.subtract(sinavSuresi);
      final (b, g) = ucretsizHakDus(bitmis: sinavSayisi, gunlukTarih: gunlukTarih, simdi: baslangic);
      sinavSayisi = b;
      gunlukTarih = g;
      _p?.setInt('sinavSayisi', b);
      if (g != null) _p?.setString('gunlukTarih', g);
    }
    if (!bosSure) {
      _yanlisUcretsizAc(x.yanlislar); // bu sınavın ilk 3 yanlışı (sınavdaki sırayla) ücretsiz
      final tarih = simdi().isAfter(x.bitis) ? x.bitis : simdi();
      gecmis.add(SinavKaydi(tarih, x.puan));
      if (gecmis.length > 50) gecmis.removeRange(0, gecmis.length - 50);
      _p?.setString('gecmis', jsonEncode([for (final k in gecmis) k.toJson()]));
    }
    _p?.remove('sinavDevam');
    unawaited(sesDurdur());
  }

  void _sinavKaydet() {
    final x = _sinav;
    if (x == null || x.bitti) return;
    _p?.setString('sinavDevam', jsonEncode(x.toJson()));
  }

  /// Sonuç ekranındaki "Yanlışlarını çalış": son sınavın yanlışlarını Çalış sekmesinde açar.
  void sonSinavYanlisCalis() {
    final x = _sinav;
    if (x == null || !x.bitti) return;
    sonSinavYanlislari = x.yanlislar;
    _calisKonum.remove(filtreSinav);
    calisFiltre = filtreSinav;
    _bildir();
  }

  void sinavKapat() {
    _sinav = null;
    _p?.remove('sinavDevam');
    _bildir();
  }

  // ---- ses (Premium)
  /// Almanca soruyu ve şıkları okur. Almanca ses yoksa [SesSonucu.dilYok] döner (arayüz yardım gösterir).
  Future<SesSonucu> dinle(Soru s) async {
    if (!premium) return SesSonucu.kilitli;
    final tts = _tts;
    if (tts == null) return SesSonucu.hata;
    try {
      await tts.stop();
      final mevcut = await tts.isLanguageAvailable('de-DE');
      if (mevcut != true && mevcut != 1) return SesSonucu.dilYok;
      final dilOk = await tts.setLanguage('de-DE');
      if (dilOk == 0 || dilOk == false) return SesSonucu.dilYok;
      await tts.setSpeechRate(0.45);
      final metin = [s.de, for (var i = 0; i < s.secenekler.length; i++) '${i + 1}. ${s.secenekler[i]}'].join('. ');
      final r = await tts.speak(metin);
      if (r == 0 || r == false) return SesSonucu.hata;
      return SesSonucu.tamam;
    } catch (e) {
      if (kDebugMode) debugPrint('TTS: $e');
      return SesSonucu.hata;
    }
  }

  Future<void> sesDurdur() async {
    final tts = _tts;
    if (tts == null) return;
    try {
      await tts.stop();
    } catch (e) {
      if (kDebugMode) debugPrint('TTS stop: $e');
    }
  }

  @override
  void dispose() {
    _atildi = true;
    billing.kapat();
    super.dispose();
  }
}
