# Play Console: reklam ve ölçüm beyanları (uygulama 1.1.0)

Hazırlanma tarihi: 13 Kasım 2026. Bu rehber, 1.1.0 sürümünü (AdMob reklamları, Firebase Analytics, Firebase Remote Config, UMP rıza formu) Play Console'a bildirmek için telefondan adım adım yapılacakları anlatır.

**Önemli uyarılar**
- Play Console ekran adları zamanla ve dile göre değişir. Aşağıdaki Türkçe adlar tahmindir; emin olmadığım yerlerde "ekranda şuna benzer" yazdım. Ekrandaki adı esas al.
- Veri türü eşleştirmeleri (AdMob/Firebase verisi -> Play'deki kategori adı) Google'ın resmî sayfalarındaki veri listesine dayanır, ama kategori adlarına eşleştirme **benim yorumumdur**. Google AdMob sayfası bu eşleştirmeyi kendisi yapmadığını ve formdan geliştiricinin sorumlu olduğunu yazıyor. Yayından önce aşağıdaki kaynaklarla bir kez daha karşılaştır.
- Beyanlar, gizlilik politikasıyla (`docs/gizlilik.html`) uyumlu olmalı. Gizlilik sayfası, bu dal ana dala (main) birleşene kadar canlı değildir; formları göndermeden önce sayfanın yeni halinin yayında olduğunu kontrol et: https://ttuncaydemirr-beep.github.io/-LiD-Kocu/gizlilik.html
- Bu formları, 1.1.0 sürümünü yüklemeden önce ya da yüklerken doldur. Beyan ile uygulamanın gerçek davranışı uyuşmazsa sürüm reddedilebilir.

## Kaynaklar (Google'ın resmî sayfaları)
- AdMob (Google Mobile Ads SDK) Play veri açıklaması: https://developers.google.com/admob/android/play-data-disclosure
- Firebase Play veri açıklaması (Remote Config, Installations vb.): https://firebase.google.com/docs/android/play-data-disclosure
- Google Analytics for Firebase için hangi veriler: https://support.google.com/analytics/answer/11582702
- Play veri güvenliği formu yardımı (veri türleri ve amaçlar): https://support.google.com/googleplay/android-developer/answer/10787469
- Android'in veri türleri ve amaçları rehberi: https://developer.android.com/guide/topics/data/collect-share
- Reklam kimliği beyanı yardımı: https://support.google.com/googleplay/android-developer/answer/6048248

## 1. Reklamlar beyanı
Yol (tahmin): Play Console > uygulamayı seç > **Politika ve programlar > Uygulama içeriği** (ekranda "App content" ya da "Uygulama içeriği" kartları) > **Reklamlar**.

1. "Uygulamanız reklam içeriyor mu?" sorusuna **Evet, uygulamam reklam içeriyor** seç.
2. Kaydet.

Sonuç: mağaza sayfasında "Reklam içerir" etiketi görünür. Bu doğru; ücretsiz sürümde reklam var.

## 2. Reklam kimliği (Advertising ID) beyanı
Yol (tahmin): **Uygulama içeriği > Reklam kimliği**.

1. "Uygulamanız reklam kimliği kullanıyor mu?" sorusuna **Evet** seç.
2. Amaç (ekranda şuna benzer onay kutuları): **Reklamcılık veya pazarlama** ve **Analizler** işaretle. Başka amaç işaretleme.
3. Kaydet.

Şart: uygulamanın manifestinde `com.google.android.gms.permission.AD_ID` izni bulunmalı (reklam kararı belgesinde zaten listelenmiş). İzin yoksa Android 13 ve üzeri cihazlarda reklam kimliği sıfır döner ve beyan ile uygulama uyuşmaz. Bunu uygulama kodunu yazan ekip üyesine teyit ettir.

## 3. Veri güvenliği formu
Yol (tahmin): **Uygulama içeriği > Veri güvenliği** (ekranda "Data safety").

### 3.1 Genel sorular
| Soru (ekranda şuna benzer) | Cevap |
|---|---|
| Uygulamanız gerekli kullanıcı verilerini topluyor veya paylaşıyor mu? | **Evet** |
| Toplanan tüm kullanıcı verileri aktarım sırasında şifreleniyor mu? | **Evet.** Google AdMob sayfası ve Google Analytics sayfası SDK'nın verileri TLS ile şifreli aktardığını yazıyor; Firebase sayfası HTTPS yazıyor. Uygulamanın kendi ağ trafiği yoksa cevap Evet kalır. |
| Kullanıcılara verilerinin silinmesini isteme yolu sunuyor musunuz? | Hesap yok; uygulama sunucusunda kullanıcı verisi tutulmuyor. Google'ın tuttuğu veriler için kullanıcıya sunulan yollar: reklam kimliğini sıfırlama/silme ve Ayarlar'da "Gizlilik seçenekleri". E-posta ile talep kabul edeceksen (nilkaren.tuncay.demir@gmail.com) **Evet** seçip bu e-postayı yaz. Hangisini seçeceğine sen karar ver; sonra gizlilik politikasına da uygun olsun. |

Uygulamanın kendisi hesap, ad, e-posta, konum (GPS), fotoğraf, kişi listesi gibi veri **toplamaz**. Bunların hepsini **işaretleme**.

### 3.2 Hangi veri türleri işaretlenir
Aşağıdaki tablo Google'ın AdMob ve Google Analytics sayfalarındaki veri listelerinden çıkarıldı. "Play kategorisi" sütunu bu listelerin Play'in kendi kategori adlarına benim eşleştirmemdir (ekranda adlar biraz farklı olabilir).

| Google'ın yazdığı veri | Play'de kategori (tahmini ad) | Toplanıyor | Paylaşılıyor | Amaçlar | Kaynak |
|---|---|---|---|---|---|
| IP adresi (yaklaşık konum çıkarılabilir) | **Konum > Yaklaşık konum** | Evet | Evet (AdMob) | Reklamcılık veya pazarlama; Analizler; Dolandırıcılık önleme, güvenlik ve uyumluluk | AdMob, Analytics |
| Uygulama başlatma, dokunma, video izleme | **Uygulama etkinliği > Uygulama etkileşimleri** | Evet | Evet (AdMob) | Reklamcılık veya pazarlama; Analizler; Dolandırıcılık önleme | AdMob |
| Sınav başladı/bitti, ekran görüntüleme, oturum (Analytics olayları) | **Uygulama etkinliği > Uygulama etkileşimleri** | Evet | Aşağıdaki nota bak | Analizler | Analytics |
| Uygulama ve SDK performansı (açılış süresi, takılma, enerji) | **Uygulama bilgileri ve performansı > Teşhisler** (ekranda "Diagnostics" olabilir) | Evet | Evet (AdMob) | Analizler; Dolandırıcılık önleme | AdMob |
| Android reklam kimliği, uygulama grubu kimliği (app set ID), uygulama örneği kimliği, Firebase yükleme kimliği | **Cihaz veya diğer kimlikler** | Evet | Evet (AdMob) | Reklamcılık veya pazarlama; Analizler; Dolandırıcılık önleme | AdMob, Analytics, Firebase |
| Uygulama içi satın alma olayı (ürün kimliği, ad, fiyat) | **Finansal bilgiler > Satın alma geçmişi** (ekranda "Purchase history" olabilir) | Evet | Aşağıdaki nota bak | Analizler | Analytics |
| Dil, ülke, saat dilimi, işletim sistemi ve uygulama sürümü (Remote Config) | Ayrı bir kategori istemiyor; Remote Config sayfası bunları "otomatik toplanan" yazıyor. Cihaz bilgisi için Play'de uygun kategori görünüyorsa işaretle, yoksa işaretlemeye gerek görmeyebilirsin. **Emin değilim; yayından önce Firebase sayfasına bak.** | Evet | Hayır (Firebase sayfası: üçüncü taraflara aktarılmaz, istisnası bu geliştiricinin talimatıyla yapılan aktarımlar ve Firebase'in alt işleyicileri) | Uygulama işlevselliği | Firebase |

**"Toplanıyor" ile "Paylaşılıyor" farkı (ekranda şuna benzer):**
- AdMob sayfası bu verileri "otomatik toplanan **ve paylaşılan**" olarak listeliyor (reklam, analiz ve dolandırıcılık önleme amaçlı). Bu yüzden AdMob'dan gelen tüm türler için "Paylaşılıyor"u işaretle.
- Analytics ve Remote Config için Google'ın sayfaları paylaşımı ayrıntılı anlatmıyor. Play yardımı, geliştiricinin kendi adına veriyi işleyen hizmet sağlayıcıya aktarmayı "paylaşma" saymayabilir; ama bu karar senin sorumluluğunda. Aynı veri türleri AdMob nedeniyle zaten "Paylaşılıyor" işaretli olacağı için Analytics'i ayrıca düşünmen gerekmeyebilir; yine de Satın alma geçmişi türü yalnızca Analytics'ten geldiği için orada karar vermen gerekir. **Emin değilim; Play yardımı sayfasındaki "paylaşma" tanımına bak:** https://support.google.com/googleplay/android-developer/answer/10787469

### 3.3 Her veri türü için alt sorular (ekranda şuna benzer)
- **"Bu veri toplanıyor mu, paylaşılıyor mu, ikisi de mi?"** Yukarıdaki tabloya göre seç.
- **"Bu veri işlenirken geçici mi işleniyor?"** (ekranda "Ephemeral processing") **Hayır.** Google bu verileri reklam ve analiz için saklıyor; geçici sayılmaz.
- **"Bu verinin toplanması zorunlu mu, isteğe bağlı mı?"** Reklam kimliği için **isteğe bağlı** seç: kullanıcı kimliği sıfırlayabilir/silebilir ve AB/AEA/İngiltere/İsviçre'de rıza formundan reddedebilir (AdMob sayfası: reklam kimliği toplama isteğe bağlıdır). Diğer türlerde kesin bir Google ifadesi bulamadım; rıza vermeyen kullanıcı uygulamayı yine kullanabildiği için "isteğe bağlı" daha doğru görünüyor, ama **emin değilim**.
- **Amaçlar:** tablodaki gibi işaretle. "Kişiselleştirme" amacını yalnızca kişiselleştirilmiş reklam için ayrıca işaretlemek gerekebilir; Google'ın AdMob sayfası amaçları "reklam, analiz ve dolandırıcılık önleme" diye yazıyor. Play'de "Reklamcılık veya pazarlama" bu kapsamı karşılıyor; ayrıca "Kişiselleştirme"yi işaretlemek zorunda olup olmadığından **emin değilim**.

### 3.4 Gizlilik politikası bağlantısı
Veri güvenliği formunun sonunda (ya da Mağaza ayarları > Gizlilik politikası) şu adres yazılı olmalı:
`https://ttuncaydemirr-beep.github.io/-LiD-Kocu/gizlilik.html`

## 4. Mağaza metni
- Tam açıklama ve uygulama içi ürün açıklamaları için `docs/magaza-kaydi.md` içindeki güncel metinleri 4 dile yapıştır (reklam ve "Premium reklamsız" ifadeleri eklendi).
- Eski "reklamsız / veri toplanmaz" cümleleri kalmamalı; kalırsa "yanıltıcı beyan" riski doğar.

## 5. Hedef kitle ve içerik
- **Hedef kitle ve içerik:** 18 yaş ve üzeri seçili kalsın; uygulama çocuklara yönelik değil (gizlilik politikasıyla aynı). Çocuklara yönelik seçilirse reklam SDK'sı için ek sertifikalı reklam kuralları devreye girer.
- AdMob konsolunda, AB/AEA/İngiltere için rıza mesajının (Gizlilik ve mesajlaşma bölümü) yayında olduğunu ve uygulamadaki UMP ile uyumlu çalıştığını kontrol et (ayrı iş; bu belge kapsamı dışında).

## 6. Gönderim sırası
1. Reklamlar > Evet
2. Reklam kimliği > Evet (reklam ve analiz)
3. Veri güvenliği formu > Önizleme sayfasını kontrol et > Gönder
4. Mağaza metinlerini güncelle
5. 1.1.0 AAB'yi yükle, sürüm notlarını yaz
6. "Uygulama içeriği" sayfasında hiçbir kartın uyarı göstermediğini kontrol et
