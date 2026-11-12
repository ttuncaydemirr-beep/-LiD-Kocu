# Reklam kararı (12.11.2026)

Ekip araştırması (rakip reklam düzenleri, AdMob eCPM, Play/AdMob politikaları) sonrası Tuncay'ın onayladığı düzen.
Reklamlar yalnızca Premium olmayanlara gösterilir. Premium kullanıcıda reklam SDK'sı hiç başlatılmaz.

| # | Karar | Ayrıntı |
|---|---|---|
| 1 | İsteğe bağlı ödüllü reklam | Günlük ücretsiz deneme hakkı bitince "Reklam izle, 1 deneme daha aç" seçeneği. Reklam tamamlanınca 1 ek deneme hakkı verilir. |
| 2 | Sınav sonunda geçiş reklamı | **Her** deneme sınavı sonucundan sonra 1 geçiş reklamı. Sonuç ekranı göründükten sonra gösterilir; sınav sırasında ve uygulama açılışında asla gösterilmez. |
| 3 | Premium = reklamsız | Premium satış ekranında ve mağaza metinlerinde "reklamsız" Premium avantajı olarak yazılır. |
| 4 | İlk gün muafiyeti yok | Reklamlar kurulumdan itibaren geçerlidir. |

Reddedilenler: açılışta reklam (AdMob interstitial politikası açılışta göstermeyi yasaklar), sınav başında reklam (en çok rahatsızlık yaratan yer).

## Zamanlama
Kapalı test (14 gün) bitip üretim yayını yapıldıktan sonraki ilk güncellemede.

## Reklamla birlikte yapılacak zorunlu işler
- `google_mobile_ads` paketi, AdMob uygulama kimliği, ödüllü ve geçiş reklam birimleri
- AB/AEA/İsviçre için Google UMP rıza ekranı (TCF, sertifikalı CMP) ve Ayarlar'da "Gizlilik seçenekleri"
- Manifestte `AD_ID` izni
- Play Console: "Reklam içeriyor" = Evet; Veri güvenliği formu (AdMob verileri); Reklam kimliği beyanı
- Gizlilik politikası (4 dil): "veri toplanmaz" kaldırılır, AdMob ve rıza bölümü eklenir
- Mağaza metinleri (4 dil): "reklamsız / veri toplanmaz" ifadeleri değişir, Premium'a "reklamsız" eklenir
- Uygulama içi Premium metinleri (4 dil)
