"""Klarheit renklerini tek kaynaktan (tasarim/tokens.json) üretir:
- flutter/lid_kocu/lib/ui/renk.dart          (Renk sınıfı: açık, koyu ve iki renk körü teması)
- web/src/index.html                         (/*RENKLER*/ ... /*RENKLER SONU*/ arası)
- android res/values{,-night}/colors.xml     (açılış zemini = kagit)
Renk değiştirmek için yalnızca tokens.json düzenlenir, sonra: python3 web/tools/derle.py"""
import json, pathlib, re

kok = pathlib.Path(__file__).resolve().parent.parent
T = json.loads((kok / "tasarim/tokens.json").read_text(encoding="utf-8"))
renkler = T["color"]["tokens"]
deger = {r["name"]: r["value"] for r in renkler}

# Web önizlemesindeki CSS değişken adları (tokens.json adı -> web adı).
WEB = {
    "kagit": "paper", "sayfa": "sheet", "yazi": "ink", "soluk": "muted", "cizgi": "line",
    "secenekKenar": "control", "vurgu": "accent", "vurguUstu": "on-accent", "isaret": "mark",
    "isaretUstu": "on-mark", "dogru": "good", "dogruZemin": "good-bg", "yanlis": "bad", "yanlisZemin": "bad-bg",
}
assert set(WEB) == set(deger), f"tokens.json renkleri ile WEB eşlemesi farklı: {set(WEB) ^ set(deger)}"


def hexx(v):
    assert re.fullmatch(r"#[0-9a-f]{6}", v), f"yalnızca #rrggbb destekleniyor: {v}"
    return v


# --- Flutter ---------------------------------------------------------------
adlar = [r["name"] for r in renkler]


def dart_tema(tema):
    satir = [f"    {a}: Color(0xFF{hexx(deger[a][tema])[1:].upper()})," for a in adlar]
    return "\n".join(satir)


alanlar = "\n".join(f"  /// {r['usage']}\n  final Color {r['name']};" for r in renkler)
kopya_param = ", ".join(f"Color? {a}" for a in adlar)
kopya_govde = "\n".join(f"      {a}: {a} ?? this.{a}," for a in adlar)
gecis_govde = "\n".join(f"      {a}: Color.lerp({a}, other.{a}, t)!," for a in adlar)
dart = f"""// ÜRETİLDİ: tasarim/tokens.json -> tasarim/uret.py (python3 web/tools/derle.py). Elle değiştirme.
// Renk belirteçleri ("Klarheit" görsel kimliği). Metin/zemin çiftleri WCAG AA (4.5:1),
// şık çerçevesi ve vurgu çizgileri en az 3:1 sağlar.
import 'package:flutter/material.dart';

/// Temaya eklenen renk paleti (ThemeExtension). Okumak için: `Renk.of(context)`.
@immutable
class Renk extends ThemeExtension<Renk> {{
{alanlar}

  const Renk({{
{chr(10).join(f"    required this.{a}," for a in adlar)}
  }});

  static const Renk acik = Renk(
{dart_tema("light")}
  );

  static const Renk koyu = Renk(
{dart_tema("dark")}
  );

  /// Renk körü modu, açık tema: doğru mavi, yanlış turuncu; diğer renkler `acik` ile aynı.
  static const Renk renkKoruAcik = Renk(
{dart_tema("cvd-light")}
  );

  /// Renk körü modu, koyu tema: doğru mavi, yanlış turuncu; diğer renkler `koyu` ile aynı.
  static const Renk renkKoruKoyu = Renk(
{dart_tema("cvd-dark")}
  );

  /// Parlaklık ve renk körü ayarına göre palet.
  static Renk sec(Brightness b, {{bool renkKoru = false}}) => b == Brightness.dark
      ? (renkKoru ? renkKoruKoyu : koyu)
      : (renkKoru ? renkKoruAcik : acik);

  static Renk of(BuildContext context) {{
    final t = Theme.of(context);
    return t.extension<Renk>() ?? sec(t.brightness);
  }}

  @override
  Renk copyWith({{{kopya_param}}}) {{
    return Renk(
{kopya_govde}
    );
  }}

  @override
  Renk lerp(Renk? other, double t) {{
    if (other == null) return this;
    return Renk(
{gecis_govde}
    );
  }}
}}
"""
(kok / "flutter/lid_kocu/lib/ui/renk.dart").write_text(dart, encoding="utf-8")


# --- Web -------------------------------------------------------------------
def css(tema):
    parca = [f"--{WEB[a]}:{hexx(deger[a][tema])}" for a in adlar]
    return ";".join(parca)


blok = (
    "/*RENKLER: tasarim/tokens.json'dan üretilir (python3 web/tools/derle.py). Elle değiştirme.*/\n"
    f":root{{{css('light')}}}\n"
    f'@media (prefers-color-scheme:dark){{:root:not([data-theme="light"]){{{css("dark")};color-scheme:dark}}}}\n'
    f':root[data-theme="dark"]{{{css("dark")};color-scheme:dark}}\n'
    "/*RENKLER SONU*/"
)
yol = kok / "web/src/index.html"
html = yol.read_text(encoding="utf-8")
yeni, n = re.subn(r"/\*RENKLER:.*?/\*RENKLER SONU\*/", lambda _: blok, html, flags=re.S)
assert n == 1, "web/src/index.html içinde /*RENKLER: ... /*RENKLER SONU*/ bloğu bulunamadı"
yol.write_text(yeni, encoding="utf-8")

# --- Android ---------------------------------------------------------------
res = kok / "flutter/lid_kocu/android/app/src/main/res"
for klasor, tema in (("values", "light"), ("values-night", "dark")):
    (res / klasor / "colors.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<!-- ÜRETİLDİ: tasarim/tokens.json (kagit). Elle değiştirme. -->\n"
        "<resources>\n"
        f'    <color name="app_bg">{deger["kagit"][tema].upper()}</color>\n'
        "</resources>\n",
        encoding="utf-8",
    )

print("tasarım: renk.dart, web renkleri, colors.xml üretildi;", len(adlar), "renk")
