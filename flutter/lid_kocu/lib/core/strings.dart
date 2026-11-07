// LiD Koçu — arayüz metinleri (assets/data/metin.json): dört dil, {ad} yer tutucuları.
class Strings {
  const Strings(this._m);
  final Map<String, Map<String, String>> _m;

  static final RegExp _ph = RegExp(r'\{(\w+)\}');

  Iterable<String> get languages => _m.keys;
  Iterable<String> keysOf(String lang) => (_m[lang] ?? const <String, String>{}).keys;

  /// [lang] dilindeki metin; yoksa Türkçe, o da yoksa anahtarın kendisi. {ad} yer tutucuları [params] ile doldurulur.
  String t(String lang, String key, [Map<String, Object> params = const <String, Object>{}]) {
    final String raw = _m[lang]?[key] ?? _m['tr']?[key] ?? key;
    if (params.isEmpty) return raw;
    return raw.replaceAllMapped(_ph, (Match m) => '${params[m.group(1)] ?? m.group(0)}');
  }

  factory Strings.fromJson(Map<String, dynamic> j) => Strings(<String, Map<String, String>>{
        for (final MapEntry<String, dynamic> e in j.entries)
          e.key: <String, String>{
            for (final MapEntry<String, dynamic> k in (e.value as Map<String, dynamic>).entries) k.key: k.value as String,
          },
      });
}
