// LiD Koçu — Play satın alma imzası doğrulaması için genel anahtar.
//
// Play Console > Para kazanma kurulumu > Lisanslama'dan kopyala.
// ("Play Faturalandırma için lisans anahtarı": uzun, tek satırlık base64 metin.)
// Bu bir GENEL anahtardır, sır değildir; depoya yazılması güvenlidir.
//
// Boşsa doğrulama atlanır ve satın alma davranışı değişmez. Doluysa imzası tutmayan satın alma/geri yükleme
// kaydı "gerçek değil" sayılır: Premium verilmez ve onaylanmaz (bkz. imza_dogrula.dart, billing.dart).
// Yanlış yapıştırılmış bir anahtar gerçek alımları da reddeder; yapıştırdıktan sonra Play'in dahili test
// kanalında bir satın alma deneyin. (test/imza_dogrula_test.dart anahtarın çözülebildiğini de sınar.)
const String playLisansAnahtari = '';
