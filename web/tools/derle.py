"""web/src/index.html içine katalog ve çevirileri gömer → web/dist/index.html.
Ayrıca Flutter varlıklarını (assets/katalog.json, assets/ceviriler.json) aynı kaynaktan üretir."""
import json, pathlib

kok = pathlib.Path(__file__).resolve().parent.parent
app = kok.parent / "flutter/lid_kocu/assets"
B = json.loads((kok / "veri/birlesik.json").read_text(encoding="utf-8"))
kisa = lambda q: {"id": q["id"], "de": q["de"], "o": q["o"], "c": q["c"]}
K = {"stand": "07.05.2025", "general": [kisa(q) for q in B if not q["bl"]], "states": {}}
for q in B:
    if q["bl"]:
        K["states"].setdefault(q["bl"], {"name": q["blad"], "q": []})["q"].append(kisa(q))
C = json.loads((kok / "veri/ceviriler-tam.json").read_text(encoding="utf-8"))
for k, v in json.loads((kok / "veri/gorselli.json").read_text(encoding="utf-8")).items():
    C[k] = {d: v[d] for d in ("en", "tr", "ar", "de")}
sk = lambda x: json.dumps(x, ensure_ascii=False, separators=(",", ":"))
guvenli = lambda s: s.replace("</", "<\\/")
html = (kok / "src/index.html").read_text(encoding="utf-8")
html = html.replace("/*KATALOG*/null", guvenli(sk(K))).replace("/*CEVIRI*/null", guvenli(sk(C)))
(kok / "dist").mkdir(exist_ok=True)
(kok / "dist/index.html").write_text(html, encoding="utf-8")
(app / "katalog.json").write_text(sk(K), encoding="utf-8")
(app / "ceviriler.json").write_text(sk(C), encoding="utf-8")
print("web", len(html.encode()), "bayt; sorular", len(K["general"]) + sum(len(v["q"]) for v in K["states"].values()), "; çeviriler", len(C))

# Tasarım renkleri (tasarim/tokens.json) -> renk.dart, web renk bloğu, Android colors.xml
import runpy
runpy.run_path(str(kok.parent / "tasarim/uret.py"))
