#!/usr/bin/env node
// kaynak/prototip.html -> flutter/lid_kocu/assets/data/{katalog,ceviri}.json
// Prototipteki K (soru kataloğu) ve T (çeviri + açıklama) verisini çıkarır. Arayüz metinleri (metin.json) elle bakılır,
// bu betik onları ÜSTÜNE YAZMAZ.
// Kullanım: node tools/veri-cikar.js
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.join(__dirname, '..');
const html = fs.readFileSync(path.join(ROOT, 'kaynak', 'prototip.html'), 'utf8');
const a = html.indexOf('const K=');
const b = html.indexOf('const SUPPORT=');
if (a < 0 || b < 0) throw new Error('prototipte K/T bloğu bulunamadı');
// Yalnızca veri bildirimleri (K ve T) kapalı bir vm bağlamında değerlendirilir.
const ctx = vm.createContext({});
vm.runInContext(html.slice(a, b) + '\n;this.K=K;this.T=T;', ctx, { timeout: 10000 });
const K = ctx.K, T = ctx.T;
const dm = html.match(/const DATED=\[([^\]]*)\]/);
const dated = dm ? dm[1].split(',').map((s) => s.trim()).filter(Boolean) : [];
// Eyaletlerde belediye seçimi oy yaşı (her eyalette -4) yasayla sık değişir: bunlar da "güncel olabilir" işaretlenir.
for (const s of Object.values(K.states)) for (const q of s.q) if (q.de.startsWith('Ab welchem Alter')) dated.push(String(q.id));

const qOut = (q) => ({ id: String(q.id), de: q.de, o: q.o, c: q.c });
const katalog = {
  stand: K.stand,
  dated, // cevabı zamanla değişebilen sorular: arayüzde "güncel olabilir" uyarısı
  general: K.general.map(qOut),
  states: Object.entries(K.states).map(([id, s]) => ({ id, name: s.name, q: s.q.map(qOut) })),
};
const ceviri = {};
for (const [id, v] of Object.entries(T)) {
  const o = {};
  for (const lang of ['tr', 'en', 'de', 'ar']) if (v[lang]) o[lang] = v[lang]; // prototipteki geliştirici notu ("not") dışarıda
  ceviri[id] = o;
}
const out = path.join(ROOT, 'flutter', 'lid_kocu', 'assets', 'data');
fs.mkdirSync(out, { recursive: true });
fs.writeFileSync(path.join(out, 'katalog.json'), JSON.stringify(katalog));
fs.writeFileSync(path.join(out, 'ceviri.json'), JSON.stringify(ceviri));
console.log('katalog.json:', katalog.general.length, 'genel +', katalog.states.length, 'eyalet; ceviri.json:', Object.keys(ceviri).length, 'soru; dated:', dated.join(','));
