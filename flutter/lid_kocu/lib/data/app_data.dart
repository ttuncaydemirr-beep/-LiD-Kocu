// LiD Koçu — gömülü JSON verisinin yüklenmesi.
import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/models.dart';
import '../core/strings.dart';

class AppData {
  const AppData({required this.catalog, required this.translations, required this.strings});
  final Catalog catalog;
  final Translations translations;
  final Strings strings;

  static Future<AppData> load([AssetBundle? bundle]) async {
    final AssetBundle b = bundle ?? rootBundle;
    final List<String> raw = await Future.wait(<Future<String>>[
      b.loadString('assets/data/katalog.json'),
      b.loadString('assets/data/ceviri.json'),
      b.loadString('assets/data/metin.json'),
    ]);
    return AppData(
      catalog: Catalog.fromJson(jsonDecode(raw[0]) as Map<String, dynamic>),
      translations: Translations.fromJson(jsonDecode(raw[1]) as Map<String, dynamic>),
      strings: Strings.fromJson(jsonDecode(raw[2]) as Map<String, dynamic>),
    );
  }
}
