// ÜRETİLDİ: tasarim/tokens.json -> tasarim/uret.py (python3 web/tools/derle.py). Elle değiştirme.
// Renk belirteçleri ("Klarheit" görsel kimliği). Metin/zemin çiftleri WCAG AA (4.5:1),
// şık çerçevesi ve vurgu çizgileri en az 3:1 sağlar.
import 'package:flutter/material.dart';

/// Temaya eklenen renk paleti (ThemeExtension). Okumak için: `Renk.of(context)`.
@immutable
class Renk extends ThemeExtension<Renk> {
  /// Kâğıt: her ekranın arkasındaki zemin ve kart içindeki görsel açıklamasının iç zemini. Dolu `yazi` üzerindeki metin rengi de budur (seçili dil tuşu, cevaplanmış şerit kutusu).
  final Color kagit;
  /// Sayfa: Kart, Acilir, şık yüzeyleri, diyaloglar. Ayrıca onError ve sonuç şeridinde dolu `yanlis` kutudaki numara.
  final Color sayfa;
  /// Mürekkep: kagit, sayfa, dogruZemin ve yanlisZemin üzerindeki tüm ana metin (kagit üzerinde açıkta 14,5:1, koyuda 15,4:1). Seçili dil tuşu, cevaplanmış şerit kutusu ve bildirim çubuğu zemini.
  final Color yazi;
  /// Soluk metin (SolukMetin): Almanca satırın altındaki çeviriler, ipuçları, tarihler, alt bilgi, cevaplanmamış şerit numaraları. Açıkta kagit üzerinde 5,5:1, yanlisZemin üzerinde 5,1:1; koyuda sayfa üzerinde 7,2:1.
  final Color soluk;
  /// İnce çizgi: Kart çerçevesi (1 px), sekme taban çizgisi (2 px), cevaplanmamış şerit kutusu, ilerleme izi. Yalnızca süs (sayfa üzerinde 1,4:1): kontrol sınırı olarak kullanma, orada secenekKenar kullan.
  final Color cizgi;
  /// Dururken kontrol sınırı (1,5 px): cevap şıkları ve Acilir. Açıkta sayfa üzerinde 4,1:1, koyuda 4,8:1: 3:1'i geçer.
  final Color secenekKenar;
  /// Vurgu (ColorScheme.primary): dolu düğme zemini, çerçeveli ve metin düğmesinin yazısı ve 1,5 px çerçevesi, seçili şık çerçevesi (2,5 px), etkin sekme alt çizgisi (3 px), geçerli şerit kutusu, ilerleme dolgusu, bağlantılar, odak. Metin olarak açıkta sayfa üzerinde 8,4:1, koyuda 7,0:1.
  final Color vurgu;
  /// vurgu dolgusu üzerindeki metin ve simgeler (onPrimary). Açıkta beyaz; koyuda lacivert, çünkü koyu temada vurgu açık renktir.
  final Color vurguUstu;
  /// İşaret sarısı (secondary): Etiket'ler, logo yazısındaki 'Koçu' etiketi, açıklamanın yanındaki 4 px başlangıç çizgisi. İki temada aynı. Açık zeminde asla metin olarak kullanma (kagit üzerinde 1,4:1).
  final Color isaret;
  /// isaret üzerindeki metin (10,3:1).
  final Color isaretUstu;
  /// Doğru: doğru şıkkın çerçevesi ve check_circle simgesi, 'Doğru.' geri bildirimi, verified simgeleri, doğru şerit kutuları. Açıkta dogruZemin üzerinde 4,7:1. dogru ve yanlis yalnızca renk tonuyla ayrılır (aralarında 1,2:1); yanına simge, kelime ya da açıklık farkı ekle. Renk körü temalarında mavi (#0066a8 / #7cc4f5): yanlış turuncusundan döteranopi ve protanopide de açıkça ayrılır.
  final Color dogru;
  /// Doğru şıkkın ya da doğru şerit kutusunun arkasındaki açık ton; 'Geçtin' etiketinin zemini. Renk körü temalarında açık mavi ton.
  final Color dogruZemin;
  /// Yanlış (ColorScheme.error): yanlış şıkkın çerçevesi ve cancel simgesi, 'Yanlış.' geri bildirimi, kalınan sınavın teklif kartı çerçevesi, sonuç şeridinde yanlış ya da boş kutunun dolu zemini (numara sayfa renginde, açıkta 6,5:1, koyuda 8,0:1). Açıkta yanlisZemin üzerinde 5,5:1, koyuda 7,0:1. Renk körü temalarında turuncu (#a64400 / #ffae5e).
  final Color yanlis;
  /// Yanlış şıkkın arkasındaki açık ton, kalınan sınavdan sonraki teklif kartı ve 'Bu sefer olmadı' etiketinin zemini. Renk körü temalarında açık turuncu ton.
  final Color yanlisZemin;

  const Renk({
    required this.kagit,
    required this.sayfa,
    required this.yazi,
    required this.soluk,
    required this.cizgi,
    required this.secenekKenar,
    required this.vurgu,
    required this.vurguUstu,
    required this.isaret,
    required this.isaretUstu,
    required this.dogru,
    required this.dogruZemin,
    required this.yanlis,
    required this.yanlisZemin,
  });

  static const Renk acik = Renk(
    kagit: Color(0xFFF3F6FB),
    sayfa: Color(0xFFFFFFFF),
    yazi: Color(0xFF14233B),
    soluk: Color(0xFF566479),
    cizgi: Color(0xFFD3DBE6),
    secenekKenar: Color(0xFF6E7F9B),
    vurgu: Color(0xFF1A47A8),
    vurguUstu: Color(0xFFFFFFFF),
    isaret: Color(0xFFFFC83D),
    isaretUstu: Color(0xFF2A2100),
    dogru: Color(0xFF0D7A4F),
    dogruZemin: Color(0xFFDFF5EA),
    yanlis: Color(0xFFB3261E),
    yanlisZemin: Color(0xFFFDE7E5),
  );

  static const Renk koyu = Renk(
    kagit: Color(0xFF0F1726),
    sayfa: Color(0xFF182235),
    yazi: Color(0xFFE9EEF6),
    soluk: Color(0xFFA3B0C4),
    cizgi: Color(0xFF2E3B52),
    secenekKenar: Color(0xFF7D8EAB),
    vurgu: Color(0xFF8AABF0),
    vurguUstu: Color(0xFF0B1630),
    isaret: Color(0xFFFFC83D),
    isaretUstu: Color(0xFF2A2100),
    dogru: Color(0xFF5FD6A4),
    dogruZemin: Color(0xFF12382A),
    yanlis: Color(0xFFFF9D94),
    yanlisZemin: Color(0xFF47201D),
  );

  /// Renk körü modu, açık tema: doğru mavi, yanlış turuncu; diğer renkler `acik` ile aynı.
  static const Renk renkKoruAcik = Renk(
    kagit: Color(0xFFF3F6FB),
    sayfa: Color(0xFFFFFFFF),
    yazi: Color(0xFF14233B),
    soluk: Color(0xFF566479),
    cizgi: Color(0xFFD3DBE6),
    secenekKenar: Color(0xFF6E7F9B),
    vurgu: Color(0xFF1A47A8),
    vurguUstu: Color(0xFFFFFFFF),
    isaret: Color(0xFFFFC83D),
    isaretUstu: Color(0xFF2A2100),
    dogru: Color(0xFF0066A8),
    dogruZemin: Color(0xFFE1EEFA),
    yanlis: Color(0xFFA64400),
    yanlisZemin: Color(0xFFFDE9D6),
  );

  /// Renk körü modu, koyu tema: doğru mavi, yanlış turuncu; diğer renkler `koyu` ile aynı.
  static const Renk renkKoruKoyu = Renk(
    kagit: Color(0xFF0F1726),
    sayfa: Color(0xFF182235),
    yazi: Color(0xFFE9EEF6),
    soluk: Color(0xFFA3B0C4),
    cizgi: Color(0xFF2E3B52),
    secenekKenar: Color(0xFF7D8EAB),
    vurgu: Color(0xFF8AABF0),
    vurguUstu: Color(0xFF0B1630),
    isaret: Color(0xFFFFC83D),
    isaretUstu: Color(0xFF2A2100),
    dogru: Color(0xFF7CC4F5),
    dogruZemin: Color(0xFF0F2C45),
    yanlis: Color(0xFFFFAE5E),
    yanlisZemin: Color(0xFF4A2A0E),
  );

  /// Parlaklık ve renk körü ayarına göre palet.
  static Renk sec(Brightness b, {bool renkKoru = false}) => b == Brightness.dark
      ? (renkKoru ? renkKoruKoyu : koyu)
      : (renkKoru ? renkKoruAcik : acik);

  static Renk of(BuildContext context) {
    final t = Theme.of(context);
    return t.extension<Renk>() ?? sec(t.brightness);
  }

  @override
  Renk copyWith({Color? kagit, Color? sayfa, Color? yazi, Color? soluk, Color? cizgi, Color? secenekKenar, Color? vurgu, Color? vurguUstu, Color? isaret, Color? isaretUstu, Color? dogru, Color? dogruZemin, Color? yanlis, Color? yanlisZemin}) {
    return Renk(
      kagit: kagit ?? this.kagit,
      sayfa: sayfa ?? this.sayfa,
      yazi: yazi ?? this.yazi,
      soluk: soluk ?? this.soluk,
      cizgi: cizgi ?? this.cizgi,
      secenekKenar: secenekKenar ?? this.secenekKenar,
      vurgu: vurgu ?? this.vurgu,
      vurguUstu: vurguUstu ?? this.vurguUstu,
      isaret: isaret ?? this.isaret,
      isaretUstu: isaretUstu ?? this.isaretUstu,
      dogru: dogru ?? this.dogru,
      dogruZemin: dogruZemin ?? this.dogruZemin,
      yanlis: yanlis ?? this.yanlis,
      yanlisZemin: yanlisZemin ?? this.yanlisZemin,
    );
  }

  @override
  Renk lerp(Renk? other, double t) {
    if (other == null) return this;
    return Renk(
      kagit: Color.lerp(kagit, other.kagit, t)!,
      sayfa: Color.lerp(sayfa, other.sayfa, t)!,
      yazi: Color.lerp(yazi, other.yazi, t)!,
      soluk: Color.lerp(soluk, other.soluk, t)!,
      cizgi: Color.lerp(cizgi, other.cizgi, t)!,
      secenekKenar: Color.lerp(secenekKenar, other.secenekKenar, t)!,
      vurgu: Color.lerp(vurgu, other.vurgu, t)!,
      vurguUstu: Color.lerp(vurguUstu, other.vurguUstu, t)!,
      isaret: Color.lerp(isaret, other.isaret, t)!,
      isaretUstu: Color.lerp(isaretUstu, other.isaretUstu, t)!,
      dogru: Color.lerp(dogru, other.dogru, t)!,
      dogruZemin: Color.lerp(dogruZemin, other.dogruZemin, t)!,
      yanlis: Color.lerp(yanlis, other.yanlis, t)!,
      yanlisZemin: Color.lerp(yanlisZemin, other.yanlisZemin, t)!,
    );
  }
}
