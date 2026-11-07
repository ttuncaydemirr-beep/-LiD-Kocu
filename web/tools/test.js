// Çalışan akışı dört dilde dener: sınav kuralları, puanlama, RTL ve taşma.
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 390, height: 800 } });
  const errs = []; p.on('pageerror', e => errs.push(e.message));
  // Yazı tipleri test ortamında engelli olabilir; sayfa geri dönüş yazı tipiyle çalışmalı.
  await p.route('**/fonts.g*/**', r => r.abort());
  await p.goto('file://' + path.resolve(__dirname, '../dist/index.html'));
  const sonuc = await p.evaluate(() => {
    const keys = Object.keys(K.states), hata = [];
    for (let n = 0; n < 500; n++) {
      S.state = keys[n % keys.length];
      const e = pickExam(), ids = new Set(e.map(q => q.id));
      const eyalet = e.filter(q => String(q.id).includes('-')).length;
      if (e.length !== 33 || ids.size !== 33 || eyalet !== 3) hata.push([n, e.length, ids.size, eyalet]);
    }
    S.state = 'berlin';
    const veri = pool().filter(q => q.o.length !== 4 || q.c < 0 || q.c > 3 || !q.de).length;
    const cevriOk = Object.values(T).every(x => ['tr', 'en', 'ar'].every(l => x[l].q && x[l].o.length === 4 && x[l].x) && x.de.x);
    const mk = c => { const qs = pickExam(); return { qs, ans: qs.map((q, i) => i < c ? q.c : (q.c + 1) % 4) }; };
    return { hata: hata.length, veri, cevriOk, s16: scoreOf(mk(16)), s17: scoreOf(mk(17)), toplam: K.general.length };
  });
  console.log(sonuc);
  for (const l of ['tr', 'en', 'de', 'ar']) {
    await p.click(`#langs [data-l="${l}"]`);
    const r = await p.evaluate(() => ({ dir: document.documentElement.dir, tasma: document.documentElement.scrollWidth > innerWidth, eksik: /undefined|\{[a-z]\}/.test(document.body.innerText) }));
    console.log(l, r);
    await p.screenshot({ path: path.resolve(__dirname, `../dist/ana-${l}.png`), fullPage: true });
  }
  await p.click('#go');
  for (let i = 0; i < 33; i++) await p.click('.opt >> nth=1');
  await p.screenshot({ path: path.resolve(__dirname, '../dist/sinav-ar.png'), fullPage: true });
  await p.click('#fn');
  console.log('sonuç metni:', (await p.innerText('.big')));
  await p.screenshot({ path: path.resolve(__dirname, '../dist/sonuc-ar.png'), fullPage: true });
  console.log('js hataları:', errs);
  await b.close();
})();
