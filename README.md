# LiD Koçu

Almanya vatandaşlık testine ("Leben in Deutschland") Türkçe, İngilizce, Almanca ve Arapça hazırlık uygulaması.
Resmî değildir; BAMF veya başka bir devlet kurumunu temsil etmez. Destek: nilkaren.tuncay.demir@gmail.com

| Klasör | İçerik |
|---|---|
| `flutter/lid_kocu/` | **Asıl uygulama** (Flutter, Android kimliği `com.lidkocu.app`). Play Store'a buradan derlenir. |
| `web/` | Web önizleme ve tüm verinin kaynağı. Kurallar önce burada denenir. |
| `web/veri/` | Resmî katalog metni (Stand 07.05.2025), cevap anahtarı, özgün çeviri ve açıklamalar |
| `.github/workflows/derle.yml` | Her gönderimde analiz, test, deneme APK ve Play AAB |

## Veri
- Soru ve şık metinleri resmî BAMF PDF'inden alınmıştır. PDF doğru cevabı içermez: anahtar, iki bağımsız çözümle karşılaştırılarak kurulmuştur.
- Görselli 43 soruda fotoğraf ve arma yerine PDF'teki resmî görsel açıklamaları kullanılır (telif ve arma kullanım izinleri nedeniyle).
- Çeviri ve açıklamalar bu projede yazılmıştır; üçüncü taraf çeviri kullanılmaz.
- Veri değişince: `python3 web/tools/derle.py` (web önizlemesini ve Flutter varlıklarını birlikte günceller).
- Cevabı zamanla değişen sorular: 72, 73, 75, 236 (`lib/core/veri.dart` > `guncelSorular`).

## Satış modeli
Reklam yok. Sorular ve çevirileri ücretsiz. Tek seferlik **Premium** (ürün kimliği `premium`): tüm açıklamalar, sınırsız deneme sınavı
(ücretsiz: 2), yanlışları tekrar çalışma, sesli dinleme. Fiyat Play Console'da belirlenir; uygulama Play'in fiyatını gösterir.

## Derleme (GitHub Actions)
`main` dalına her gönderimde **Derle** iş akışı çalışır:
1. Veri kontrolü, `flutter analyze`, `flutter test`
2. **Deneme APK** → Releases > "Deneme APK". Telefona indirip kurulur (satın alma bu dosyada çalışmaz).
3. İmza anahtarı ekliyse **Play AAB** → Actions > son çalışma > Artifacts > `lid-kocu-play-aab`

### İmza anahtarı
Settings > Secrets and variables > Actions altına dört gizli değer eklenir:
`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS` (`upload`), `KEY_PASSWORD`.
Anahtar dosyası (`.jks`) ve şifresi depoya **konmaz**; iki güvenli yerde yedeklenir.

## Play Store'a ilk yükleme
1. Play Console > Uygulama oluştur: ad "LiD Koçu", varsayılan dil Türkçe, uygulama, ücretsiz.
2. Kapalı test kanalına AAB yükle; 12+ test kullanıcısını ekle, 14 gün kesintisiz test.
3. Para kazanma > Uygulama içi ürünler: kimliği `premium` olan tek seferlik ürün, etkin.
4. Mağaza kaydında ve uygulama açıklamasında "resmî değildir" uyarısı, resmî kaynak bağlantısı; BAMF logosu kullanılmaz.
5. Her yeni yüklemede `flutter/lid_kocu/pubspec.yaml` içindeki `version: 1.0.0+N` sayısını 1 artırın.

## Yayın öncesi açık işler
- 9 sorunun cevabı resmî test merkezinde elle kontrol edilecek: 297, 98, 173, 184, 73, bremen-9, nordrhein-westfalen-4, saarland-4, brandenburg-1.
- Türkçe ve Arapça metinleri birer anadil konuşuru okuyacak.
- Satın alma gerçek telefonda, kapalı test kanalından kurulmuş sürümle denenecek.
