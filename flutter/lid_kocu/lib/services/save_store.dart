// LiD Koçu — kalıcı kayıt (shared_preferences): dil, eyalet, tema, doğru/yanlış kayıtları, deneme hakkı, premium bayrağı.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SaveStore {
  SaveStore(this._p);
  final SharedPreferences _p;

  static const String _kLang = 'lang';
  static const String _kState = 'state';
  static const String _kTheme = 'theme';
  static const String _kResults = 'results';
  static const String _kExamsUsed = 'examsUsed';
  static const String _kPremium = 'premium';

  static Future<SaveStore> open() async => SaveStore(await SharedPreferences.getInstance());

  String? get lang => _p.getString(_kLang);
  Future<void> setLang(String v) => _p.setString(_kLang, v);

  String? get stateId => _p.getString(_kState);
  Future<void> setStateId(String v) => _p.setString(_kState, v);

  /// 'system' | 'light' | 'dark'
  String get theme => _p.getString(_kTheme) ?? 'system';
  Future<void> setTheme(String v) => _p.setString(_kTheme, v);

  /// Soru kimliği -> son cevabın doğru olup olmadığı.
  Map<String, bool> get results {
    final String? raw = _p.getString(_kResults);
    if (raw == null || raw.isEmpty) return <String, bool>{};
    try {
      final Map<String, dynamic> m = jsonDecode(raw) as Map<String, dynamic>;
      return <String, bool>{for (final MapEntry<String, dynamic> e in m.entries) e.key: e.value == true};
    } catch (_) {
      return <String, bool>{};
    }
  }

  Future<void> setResults(Map<String, bool> v) => _p.setString(_kResults, jsonEncode(v));

  /// Tamamlanan (bitirilen ya da süresi dolan) deneme sınavı sayısı; ücretsiz hak buna göre sınırlanır.
  int get examsUsed => _p.getInt(_kExamsUsed) ?? 0;
  Future<void> setExamsUsed(int v) => _p.setInt(_kExamsUsed, v);

  bool get premium => _p.getBool(_kPremium) ?? false;
  Future<void> setPremium(bool v) => _p.setBool(_kPremium, v);
}
