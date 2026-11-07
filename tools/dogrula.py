#!/usr/bin/env python3
"""LiD Koçu veri doğrulaması.

Kontroller (hata = çıkış kodu 1, uyarı = bilgi):
  katalog.json : 300 genel + 16 eyalet x 10 soru, her soruda 4 seçenek, doğru cevap 0-3, benzersiz kimlik
  ceviri.json  : her soru için tr/en/ar çeviri (soru + 4 seçenek) ve açıklama, Almanca açıklama, görsel açıklamaları tutarlı
  metin.json   : arayüz anahtarları tr/en/de/ar için eşit, yer tutucular ({n} vb.) dört dilde aynı
Kullanım: python3 tools/dogrula.py [veri_klasoru]
"""
import json, os, re, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
DATA = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'flutter', 'lid_kocu', 'assets', 'data')
LANGS = ('tr', 'en', 'de', 'ar')
errors, warnings = [], []
err = errors.append
warn = warnings.append


def load(name):
    with open(os.path.join(DATA, name), encoding='utf-8') as f:
        return json.load(f)


cat, tr_all, ui = load('katalog.json'), load('ceviri.json'), load('metin.json')

# ---------------------------------------------------------------- katalog
general = cat.get('general', [])
states = cat.get('states', [])
if len(general) != 300:
    err(f'genel soru sayısı {len(general)} (beklenen 300)')
if len(states) != 16:
    err(f'eyalet sayısı {len(states)} (beklenen 16)')
all_q = []
for q in general:
    all_q.append((q, 'genel'))
for s in states:
    if len(s.get('q', [])) != 10:
        err(f"{s.get('id')}: {len(s.get('q', []))} eyalet sorusu (beklenen 10)")
    for q in s.get('q', []):
        all_q.append((q, s['id']))
ids = [q['id'] for q, _ in all_q]
if len(set(ids)) != len(ids):
    err('kopya soru kimliği var')
gen_ids = [str(i) for i in range(1, 301)]
if [q['id'] for q in general] != gen_ids:
    err('genel soru kimlikleri 1..300 sırasında değil')
for s in states:
    exp = [f"{s['id']}-{i}" for i in range(1, 11)]
    if [q['id'] for q in s['q']] != exp:
        err(f"{s['id']}: eyalet soru kimlikleri {exp[0]}..{exp[-1]} sırasında değil")
n_bad_opt = n_bad_c = 0
for q, _ in all_q:
    o = q.get('o')
    if not isinstance(o, list) or len(o) != 4 or any(not isinstance(x, str) or not x.strip() for x in o):
        err(f"{q['id']}: 4 dolu seçenek yok"); n_bad_opt += 1
    elif len(set(o)) != 4:
        warn(f"{q['id']}: yinelenen seçenek metni")
    c = q.get('c')
    if not isinstance(c, int) or isinstance(c, bool) or not 0 <= c <= 3:
        err(f"{q['id']}: doğru cevap 0-3 değil ({c!r})"); n_bad_c += 1
    if not q.get('de', '').strip():
        err(f"{q['id']}: Almanca soru metni boş")
for d in cat.get('dated', []):
    if d not in ids:
        err(f'dated listesinde olmayan soru: {d}')

# ---------------------------------------------------------------- çeviri
AR = re.compile(r'[؀-ۿ]')
if set(tr_all) != set(ids):
    err(f"çeviri kimlikleri katalogla uyuşmuyor: eksik={sorted(set(ids) - set(tr_all))[:5]} fazla={sorted(set(tr_all) - set(ids))[:5]}")
miss = {l: 0 for l in ('tr', 'en', 'ar')}
for q, _ in all_q:
    t = tr_all.get(q['id'], {})
    for l in ('tr', 'en', 'ar'):
        v = t.get(l)
        ok = (isinstance(v, dict) and isinstance(v.get('q'), str) and v['q'].strip()
              and isinstance(v.get('o'), list) and len(v['o']) == 4 and all(isinstance(x, str) and x.strip() for x in v['o'])
              and isinstance(v.get('x'), str) and v['x'].strip())
        if not ok:
            err(f"{q['id']}: {l} çevirisi/açıklaması eksik veya bozuk"); miss[l] += 1
            continue
        if l == 'ar' and not AR.search(v['q'] + v['x']):
            warn(f"{q['id']}: ar metninde Arapça harf yok")
        if l == 'tr' and v['q'] == q['de']:
            warn(f"{q['id']}: tr soru metni Almancayla aynı")
    d = t.get('de')
    if not (isinstance(d, dict) and isinstance(d.get('x'), str) and d['x'].strip()):
        err(f"{q['id']}: Almanca açıklama eksik")
    # görsel açıklamaları
    gl = {l: t[l].get('g') for l in LANGS if isinstance(t.get(l), dict) and 'g' in t[l]}
    if gl:
        lens = {l: len(g) for l, g in gl.items()}
        if len(set(lens.values())) != 1 or set(gl) != set(LANGS):
            err(f"{q['id']}: görsel açıklaması dillerde tutarsız {lens}")
        elif lens['de'] not in (1, 4):
            err(f"{q['id']}: görsel açıklaması sayısı {lens['de']} (1 ya da 4 olmalı)")
        elif lens['de'] == 4 and not all(isinstance(g, str) and g.strip() for l in LANGS for g in gl[l]):
            err(f"{q['id']}: boş görsel açıklaması")
    if any(re.match(r'Bild \d', o) for o in q['o']) and 'g' not in t.get('de', {}):
        err(f"{q['id']}: seçenekleri 'Bild N' olan soruda görsel açıklaması yok")
n_img = sum(1 for q, _ in all_q if 'g' in tr_all.get(q['id'], {}).get('de', {}))

# ---------------------------------------------------------------- arayüz metinleri
if set(ui) != set(LANGS):
    err(f'metin.json dilleri {sorted(ui)} (beklenen {sorted(LANGS)})')
else:
    base = set(ui['tr'])
    for l in LANGS:
        if set(ui[l]) != base:
            err(f"metin.json {l}: eksik={sorted(base - set(ui[l]))} fazla={sorted(set(ui[l]) - base)}")
    ph = lambda s: sorted(re.findall(r'\{(\w+)\}', s))
    for k in sorted(base):
        for l in LANGS:
            v = ui[l].get(k)
            if not isinstance(v, str) or not v.strip():
                err(f'metin.json {l}.{k} boş')
        if all(k in ui[l] for l in LANGS):
            p = {l: ph(ui[l][k]) for l in LANGS}
            if len({tuple(x) for x in p.values()}) != 1:
                err(f'metin.json {k}: yer tutucular dillerde farklı {p}')
    for k in sorted(base):
        if not AR.search(ui['ar'].get(k, '')) and k not in ('premium',):
            warn(f'metin.json ar.{k}: Arapça harf yok')

# ---------------------------------------------------------------- bilgi (hata değil)
info = []
bw = next((q for s in states if s['id'] == 'brandenburg' for q in s['q'] if q['id'] == 'brandenburg-1'), None)
if bw:
    g = tr_all['brandenburg-1']['de']['g'][bw['c']]
    info.append(f"brandenburg-1: c={bw['c']} (Bild {bw['c'] + 1}) -> '{g[:60]}...' {'KIRMIZI KARTAL (doğru)' if re.search(r'rote[mnrs]? Adler', g) else 'KIRMIZI KARTAL DEĞİL'}")
    if not re.search(r'rote[mnrs]? Adler', g):
        err('brandenburg-1: işaretli doğru cevap kırmızı kartal değil')

print('=== LiD Koçu veri doğrulaması ===')
print(f"genel: {len(general)}  eyalet: {len(states)} x {sorted({len(s['q']) for s in states})}  toplam soru: {len(all_q)}")
print(f"seçenek hatası: {n_bad_opt}  doğru-cevap hatası: {n_bad_c}  dated: {len(cat.get('dated', []))}")
print(f"çeviri eksik (tr/en/ar): {miss['tr']}/{miss['en']}/{miss['ar']}  görsel açıklamalı soru: {n_img}")
print(f"arayüz anahtarı: tr={len(ui.get('tr', {}))} en={len(ui.get('en', {}))} de={len(ui.get('de', {}))} ar={len(ui.get('ar', {}))}")
for i in info:
    print('bilgi:', i)
for w in warnings:
    print('UYARI:', w)
for e in errors:
    print('HATA:', e)
print(f'sonuç: {len(errors)} hata, {len(warnings)} uyarı')
sys.exit(1 if errors else 0)
