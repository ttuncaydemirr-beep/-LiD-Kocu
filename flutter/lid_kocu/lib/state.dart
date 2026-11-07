// LiD Koçu — uygulama durumu. Arayüz yalnızca bu sınıfla konuşur.
import 'dart:convert';

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

  String dil;
  String eyalet;
  final Map<String, bool> sonuclar;
  int sinavSayisi;
  Sinav? sinav;

  AppState._(this.katalog, this.ceviriler, this.metin, this._p, this.billing, this._tts,
      {required this.dil, required this.eyalet, required this.sonuclar, required this.sinavSayisi}) {
    billing.degisti = (v) {
      _p?.setBool('premium', v);
      notifyListeners();
    };
  }

  /// Testlerde [prefs] ve [tts] verilmeyebilir.
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
    Map<String, bool> s = {};
    try {
      final raw = p?.getString('sonuclar');
      if (raw != null) s = (jsonDecode(raw) as Map<String, dynamic>).map((a, b) => MapEntry(a, b == true));
    } catch (_) {}
    final b = Billing(sahip: p?.getBool('premium') ?? false);
    final st = AppState._(k, c, m, p, b, sesli ? FlutterTts() : null,
        dil: dil,
        eyalet: p?.getString('eyalet') ?? 'berlin',
        sonuclar: s,
        sinavSayisi: p?.getInt('sinavSayisi') ?? 0);
    if (sesli) await b.baslat();
    return st;
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
  bool aciklamaAcik(Soru s) => premium || ornekAciklama(s.id);
  bool get sinavAcik => premium || sinavSayisi < ucretsizSinav;

  Future<SatinAlmaSonucu> satinAl() async {
    final r = await billing.satinAl();
    notifyListeners();
    return r;
  }

  Future<bool?> geriYukle() async {
    final r = await billing.geriYukle();
    notifyListeners();
    return r;
  }

  // ---- ayarlar
  void dilSec(String d) {
    if (!diller.contains(d)) return;
    dil = d;
    _p?.setString('dil', d);
    notifyListeners();
  }

  void eyaletSec(String e) {
    if (!katalog.eyaletler.containsKey(e)) return;
    eyalet = e;
    _p?.setString('eyalet', e);
    notifyListeners();
  }

  // ---- çalışma
  List<Soru> get havuz => katalog.havuz(eyalet);
  int get dogruSayisi => havuz.where((s) => sonuclar[s.id] == true).length;
  List<Soru> get yanlislar => havuz.where((s) => sonuclar[s.id] == false).toList();

  Soru get gununSorusu {
    final g = katalog.genel;
    final gun = DateTime.now().difference(DateTime(2026)).inDays;
    return g[gun % g.length];
  }

  void cevapla(Soru s, int secim) {
    sonuclar[s.id] = secim == s.dogru;
    _kaydet();
    notifyListeners();
  }

  void _kaydet() => _p?.setString('sonuclar', jsonEncode(sonuclar));

  // ---- sınav
  /// Hak yoksa false döner; arayüz Premium ekranını gösterir.
  bool sinavBaslat() {
    if (!sinavAcik) return false;
    sinav = Sinav(katalog.sinavSec(eyalet), DateTime.now());
    sinavSayisi++;
    _p?.setInt('sinavSayisi', sinavSayisi);
    notifyListeners();
    return true;
  }

  void sinavCevap(int secim) {
    final x = sinav;
    if (x == null || x.bitti) return;
    x.cevaplar[x.sira] = secim;
    if (x.sira < x.sorular.length - 1) x.sira++;
    notifyListeners();
  }

  void sinavGit(int i) {
    final x = sinav;
    if (x == null || i < 0 || i >= x.sorular.length) return;
    x.sira = i;
    notifyListeners();
  }

  void sinavBitir() {
    final x = sinav;
    if (x == null || x.bitti) return;
    x.bitti = true;
    x.sira = 0;
    for (var i = 0; i < x.sorular.length; i++) {
      final c = x.cevaplar[i];
      if (c != null) sonuclar[x.sorular[i].id] = c == x.sorular[i].dogru;
    }
    _kaydet();
    notifyListeners();
  }

  void sinavKapat() {
    sinav = null;
    notifyListeners();
  }

  // ---- ses (Premium)
  Future<void> dinle(Soru s) async {
    final tts = _tts;
    if (tts == null || !premium) return;
    try {
      await tts.stop();
      await tts.setLanguage('de-DE');
      await tts.setSpeechRate(0.45);
      final metin = [s.de, for (var i = 0; i < s.secenekler.length; i++) '${i + 1}. ${s.secenekler[i]}'].join('. ');
      await tts.speak(metin);
    } catch (_) {}
  }

  Future<void> sesDurdur() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    billing.kapat();
    super.dispose();
  }
}
