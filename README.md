# LiD Koçu

Almanya vatandaşlık testine ("Leben in Deutschland") **Türkçe, İngilizce, Almanca ve Arapça (sağdan sola)** hazırlık uygulaması. Flutter ile yazılmıştır; Android uygulama kimliği `com.lidkocu.app`.

Destek: nilkaren.tuncay.demir@gmail.com · Gizlilik politikası: <https://ttuncaydemirr-beep.github.io/-LiD-Kocu/privacy.html>

## Durum (8 Kasım 2026)

- Web prototipi (`kaynak/prototip.html`) ve resmî kataloğun ham hali (`kaynak/katalog.json`, katalog tarihi 07.05.2025) depoda.
- Flutter uygulaması `flutter/lid_kocu/` altında yeniden kuruldu. Çalışan özellikler: ana sayfa (eyalet seçimi, ilerleme, bugünün sorusu), çalışma (tüm sorular / yanlışlarım, doğru-yanlış + açıklama), 33 soruluk deneme sınavı (30 genel + 3 eyalet, 60 dakika, 17 doğru ile geçme, hata incelemesi), Almanca sesli okuma, dil ve eyalet seçimi, açık/koyu tema, Premium satın alma ve geri yükleme, ayarlar.
- **Premium akışı Google Play'de henüz sınanmadı**: ürün (`premium`) Play Console'da oluşturulup uygulama iç test kanalına yüklenmeden satın alma denenemez.
- Kod geliştirme ortamında derlenemedi (Flutter SDK yoktu); analiz, test ve debug APK derlemesi GitHub Actions'ta çalışır. Güncel sonuç için Actions sekmesine bakın.

## Ürün kuralları

- **Reklam yok.** Gelir: tek seferlik "Premium" (Google Play ürün kimliği `premium`, tüketilmeyen ürün).
- Ücretsiz: 460 sorunun tamamını çalışma + **2 deneme sınavı** (bitirilen ya da süresi dolan sınavlar sayılır). Premium: sınırsız deneme sınavı. **Çeviriler hiçbir zaman ücretli değildir.** "İlerlemeyi sıfırla" deneme hakkını geri vermez.
- Sınav: 30 genel + seçilen eyaletten 3 soru = 33 soru, 60 dakika, geçmek için en az 17 doğru.
- Resimli sorularda resmî görsel yoktur (telif); resmin metin açıklaması ve resmî katalog PDF'ine bağlantı gösterilir.
- Cevabı zamanla değişebilen sorular (Başbakan, Federal Cumhurbaşkanı, Bundestag'daki en büyük gruplar, AB üye sayısı, eyaletlerde belediye seçimi oy yaşı) "güncel olabilir" uyarısıyla gösterilir (`katalog.json` içindeki `dated` listesi).

## Klasörler

| Yol | İçerik |
|---|---|
| `kaynak/` | Prototip (`prototip.html`) ve ham katalog (`katalog.json`) |
| `flutter/lid_kocu/` | Flutter projesi (`lib/`, `test/`, `android/`, `assets/data/`) |
| `flutter/lid_kocu/assets/data/` | `katalog.json` (460 soru), `ceviri.json` (tr/en/ar çeviri + açıklama, resim açıklamaları), `metin.json` (arayüz metinleri, 4 dil) |
| `tools/veri-cikar.js` | Prototipten `katalog.json` ve `ceviri.json` üretir (`metin.json` elle bakılır, üzerine yazılmaz) |
| `tools/dogrula.py` | Veri doğrulaması (soru sayıları, 4 seçenek, doğru cevap 0-3, çeviri/açıklama, arayüz anahtarı eşitliği) |
| `tools/make-icons.py` | Android ikonlarını ve `store/play-icon-512.png` dosyasını çizer (Pillow) |
| `docs/privacy.html` | Gizlilik politikası (4 dil); `pages.yml` ile GitHub Pages'e yayınlanır |
| `.github/workflows/` | `ci.yml` (doğrulama, analiz, test, debug APK), `release.yml` (elle, imzalı AAB), `pages.yml` (gizlilik sayfası) |

Kod yapısı (`flutter/lid_kocu/lib/`): `core/` saf Dart (model, sınav mantığı, metin), `data/` JSON yükleme, `services/` (kayıt, Play Billing, sesli okuma), `state/app_controller.dart`, `ui/` (tema, ortak parçalar, ekranlar).

## Nasıl derlenir

Gerekenler: Flutter stable (3.32 veya üstü), JDK 17, Android SDK 36.

```bash
cd flutter/lid_kocu
flutter pub get
flutter analyze
flutter test
flutter run                  # bağlı telefonda debug
flutter build apk --debug    # deneme APK
```

Veri değişirse (repo kökünden): `node tools/veri-cikar.js` ve `python3 tools/dogrula.py`.

### İmzalı yayın (Play Store AAB)

1. Yükleme anahtarı oluşturun (bir kez, güvenli yerde yedekleyin): `keytool -genkey -v -keystore lidkocu-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. Yerelde: `flutter/lid_kocu/android/key.properties.example` dosyasını `key.properties` olarak kopyalayıp doldurun, sonra `flutter build appbundle --release`. `key.properties` ve `.jks` dosyaları `.gitignore`'dadır; depoya girmez.
3. GitHub'da: Settings > Secrets and variables > Actions altına `ANDROID_KEYSTORE_BASE64` (`base64 -w0 lidkocu-upload.jks`), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` ekleyin; Actions > "Release AAB (imzalı)" > Run workflow. Secrets eksikse iş açık bir hata mesajıyla durur; debug anahtarıyla paket üretilmez.
4. Sürüm numarası `pubspec.yaml` içindeki `version: 1.0.0+1` satırındadır; Play'e her yüklemede `+N` kısmını artırın ve `lib/config/app_config.dart` içindeki `appVersion` değerini güncelleyin.

### Play Console'da yapılacaklar

- Uygulama içi ürün: kimlik `premium`, tek seferlik (tüketilmeyen), fiyatı siz belirlersiniz.
- Gizlilik politikası adresi: `https://ttuncaydemirr-beep.github.io/-LiD-Kocu/privacy.html` (GitHub > Settings > Pages > Source = "GitHub Actions" bir kez seçilmelidir).
- Veri güvenliği formu: reklam yok, veri toplanmıyor/paylaşılmıyor; uygulamada INTERNET izni yoktur.
- Uygulama resmî değildir (BAMF'ı temsil etmez); mağaza açıklamasında bunu belirtin.

## Bilinen eksikler ve veri notları

- Bu depoda derleme/test henüz yerelde çalıştırılamadı; CI sonucuna bakın.
- Premium satın alma uçtan uca (Play iç test kanalı) sınanmadı.
- Yazı tipleri paketlenmedi (sistem yazı tipi kullanılır; Arapça için cihazın Arapça yazı tipi).
- Resimli sorularda orijinal görseller bilinçli olarak yok (telif).
- Katalog tarihi 07.05.2025; "güncel olabilir" işaretli sorular (72, 73, 75, 236 ve her eyaletin -4 numaralı oy yaşı sorusu) yayından önce resmî kaynakla yeniden kontrol edilmeli.
- Prototipteki bir geliştirici notu: `saarland-4` (belediye seçimi oy yaşı) için Saarland'da oy yaşı yakın zamanda 16'ya inmiş olabilir; katalogdaki doğru şık 18 olarak bırakılmış ve kontrol edilmesi gerekiyor. (Not uygulamada gösterilmez; soru "güncel olabilir" uyarısı taşır.)
- Prototip çevirileri yapay zekâ ile hazırlanmıştır; yayından önce Türkçe/Arapça/İngilizce çevirilerin ana dili konuşan biri tarafından gözden geçirilmesi önerilir.
