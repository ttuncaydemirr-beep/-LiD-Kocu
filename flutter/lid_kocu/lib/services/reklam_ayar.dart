// LiD Koçu — AdMob kimlikleri. Reklam kimlikleri YALNIZCA bu dosyada tutulur.
//
// Kullanıcı AdMob kimliğini verince değiştir:
//  - admobUygulamaKimligi: AdMob > Uygulamalar > Uygulama ayarları > "Uygulama kimliği" (içinde "~" vardır).
//    android/app/build.gradle.kts bu satırı okuyup AndroidManifest'e yazar (manifestPlaceholders).
//    Boşsa manifestte Google'ın test uygulama kimliği kalır.
//  - Üç reklam birimi kimliği: AdMob > Uygulamalar > Reklam birimleri (içinde "/" vardır).
//
// Debug derlemesinde ve CI'daki "Deneme APK"da (--dart-define=TEST_REKLAM=true) Google'ın resmî TEST
// kimlikleri kullanılır. Play'e giden derlemede (release) gerçek kimlik boşsa o reklam hiç yüklenmez.

/// Android AdMob uygulama kimliği, ör. 'ca-app-pub-1234567890123456~1234567890'.
const String admobUygulamaKimligi = 'ca-app-pub-3269207938446570~2175660556';

/// Ana sayfa banner'ı (anchored adaptive) reklam birimi, ör. 'ca-app-pub-1234567890123456/1111111111'.
const String bannerBirimi = 'ca-app-pub-3269207938446570/2067849342';

/// Deneme sınavı sonucundan sonra gösterilen geçiş reklamı birimi.
const String gecisBirimi = 'ca-app-pub-3269207938446570/2434855861';

/// "Reklam izle, 1 deneme daha aç" ödüllü reklam birimi.
const String odulluBirimi = 'ca-app-pub-3269207938446570/6414288465';

// ---- Google'ın resmî Android test kimlikleri (developers.google.com/admob/android/test-ads). Değiştirmeyin.
const String testUygulamaKimligi = 'ca-app-pub-3940256099942544~3347511713';
const String testBannerBirimi = 'ca-app-pub-3940256099942544/9214589741';
const String testGecisBirimi = 'ca-app-pub-3940256099942544/1033173712';
const String testOdulluBirimi = 'ca-app-pub-3940256099942544/5224354917';

/// CI'daki deneme APK'sı test reklamlarıyla derlenir (Play AAB'si derlenmez).
const bool testReklamZorla = bool.fromEnvironment('TEST_REKLAM');
