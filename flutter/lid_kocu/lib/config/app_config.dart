// LiD Koçu — sabitler: sürüm, ürün kimliği, bağlantılar.
class AppConfig {
  AppConfig._();

  static const String appName = 'LiD Koçu';
  /// pubspec.yaml "version" satırının ad kısmıyla aynı tutulur.
  static const String appVersion = '1.0.0';

  /// Google Play Console > Uygulama içi ürünler: tek seferlik, tüketilmeyen ürün kimliği.
  static const String premiumProductId = 'premium';

  static const String supportEmail = 'nilkaren.tuncay.demir@gmail.com';
  static const String privacyUrl = 'https://ttuncaydemirr-beep.github.io/-LiD-Kocu/privacy.html';

  /// Resmî soru kataloğu (BAMF, PDF): resimli sorulardaki orijinal görseller burada.
  static const String officialCatalogUrl =
      'https://www.bamf.de/SharedDocs/Anlagen/DE/Integration/Einbuergerung/gesamtfragenkatalog-lebenindeutschland.pdf';

  static const List<String> languages = <String>['tr', 'en', 'de', 'ar'];
  static const Map<String, String> languageLabels = <String, String>{'tr': 'TR', 'en': 'EN', 'de': 'DE', 'ar': 'عر'};
  static const Map<String, String> languageNames = <String, String>{'tr': 'Türkçe', 'en': 'English', 'de': 'Deutsch', 'ar': 'العربية'};
  static const String defaultLanguage = 'tr';
  static const String defaultState = 'berlin';
}
