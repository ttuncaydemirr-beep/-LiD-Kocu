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
Sorular ve çevirileri ücretsiz. Ücretsiz: 2 deneme sınavı + her gün 1 (hak sınav bitince düşer), ilk 20 sorunun
ve günün sorusunun açıklaması, her sınavın ilk 3 yanlışının açıklaması. Tek seferlik **Premium** (ürün kimliği `premium`):
**reklamsız**, tüm açıklamalar, sınırsız deneme, yanlışların tamamı, Almanca sesli dinleme. Fiyat Play Console'da belirlenir.

**Reklam (AdMob, yalnızca Premium olmayanlara; karar: `docs/reklam-karari.md`).** Premium'da reklam SDK'sı ve rıza formu
hiç başlatılmaz; satın alma anında bütün reklamlar kalkar. İlk gün muafiyeti yok.
1. **Ödüllü:** günlük ücretsiz hak bitince Deneme sınavı ekranında "Reklam izle, 1 deneme daha aç". Reklam tamamen
   izlenince 1 ek hak (kalıcı, sınav bitince düşer; önce günün ücretsiz hakkı kullanılır). Günde en çok 3.
2. **Geçiş:** her deneme sınavı sonucundan sonra 1 kez; sonuç ekranı çizildikten ~1 sn sonra, yüklüyse. Sınav sırasında
   ve açılışta asla.
3. **Banner:** ana sayfada Premium kartının altında tek anchored adaptive banner (yeri önceden ayrılır, üstünde 24 dp boşluk).
   Sınav, çalışma kartları ve satın alma ekranında yok.
- **Rıza:** Google UMP (AB/AEA/İsviçre). Reklam yalnızca `canRequestAds` true iken istenir; gerekiyorsa alt bilgide
  "Gizlilik seçenekleri".
- **Remote Config** (varsayılanlar kodda): `reklam_banner_acik`, `reklam_gecis_acik`, `reklam_odullu_acik` (true),
  `kontrol_grubu_orani` (0.5). İlk açılışta kalıcı rastgele sayı < oran ise kullanıcı **reklamsız kontrol grubu**dur:
  banner ve geçiş görmez, ödüllü seçeneği görür. Analytics user property `reklam_grubu` = `reklamli` | `kontrol`.
- **Analytics olayları:** `sinav_basladi`, `sinav_bitti` (puan, gecti), `premium_ekrani`, `satin_alma`, `odullu_izlendi`,
  `gecis_gosterildi`, `banner_yuklendi`, `banner_yuklenemedi`.
- **Kimlikler:** AdMob uygulama ve 3 birim kimliği yalnızca `flutter/lid_kocu/lib/services/reklam_ayar.dart` içinde.
  Boşken Play derlemesinde reklam yüklenmez; debug ve Deneme APK Google test reklamlarını gösterir.
- **Firebase:** `flutter/lid_kocu/android/app/google-services.json` (depoya konur) veya Actions gizli değeri
  `GOOGLE_SERVICES_JSON` (dosyanın içeriği). Yoksa uygulama Firebase'siz çalışır, olaylar boşa düşer.

Mağaza metinleri (4 dil): `docs/magaza-kaydi.md`. Gizlilik: `docs/gizlilik.html` (GitHub Pages).

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
5. Her yeni yüklemede `flutter/lid_kocu/pubspec.yaml` içindeki `version: X.Y.Z+N` sayısını (N) 1 artırın.

## Yayın öncesi açık işler
- Türkçe ve Arapça metinleri birer anadil konuşuru okuyacak.

Tamamlananlar (12.11.2026): şüpheli 9 sorunun cevabı (73, 98, 173, 184, 297, bremen-9, nordrhein-westfalen-4,
saarland-4, brandenburg-1) resmî BAMF test merkezinde kontrol edildi, hepsi doğru. Satın alma (promosyon koduyla)
kapalı test sürümünde gerçek telefonda denendi, Premium açıldı. Mağaza kaydı 4 dilde hazır.
