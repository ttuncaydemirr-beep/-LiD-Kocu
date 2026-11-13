// İlk açılış: dil seçimi (4 büyük düğme, cihaz dili ön seçili ama onay ister), eyalet seçimi ve
// "resmî değildir" uyarısı. Bir kez gösterilir; dil ve eyalet sonra ana sayfadan değiştirilebilir.
import 'package:flutter/material.dart';

import '../state.dart';
import 'durum.dart';
import 'tema.dart';

/// Her dilin kendi adıyla gösterimi.
const Map<String, String> dilAdlari = {'tr': 'Türkçe', 'en': 'English', 'de': 'Deutsch', 'ar': 'العربية'};

/// Dil seçim ekranındaki sıra: hedef kitle önce.
const List<String> _kurulumDilleri = ['tr', 'ar', 'en', 'de'];

class IlkAcilis extends StatefulWidget {
  const IlkAcilis({super.key});

  @override
  State<IlkAcilis> createState() => _IlkAcilisDurumu();
}

class _IlkAcilisDurumu extends State<IlkAcilis> {
  int _adim = 0;
  String? _eyalet;

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    return _adim == 0 ? _dilAdimi(s) : _eyaletAdimi(s);
  }

  Widget _dilAdimi(AppState s) {
    final r = Renk.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Bosluk.b14,
      children: [
        // Başlık dört dilde: telefon dili ne olursa olsun herkes kendi dilini bulur.
        Semantics(
          header: true,
          child: Text(
            [for (final d in _kurulumDilleri) s.metin.t(d, 'chooseLang')].join(' · '),
            style: Yazi.baslikOrta,
          ),
        ),
        for (final d in _kurulumDilleri)
          Semantics(
            button: true,
            selected: s.dil == d,
            label: dilAdlari[d],
            excludeSemantics: true,
            onTap: () => s.dilSec(d),
            child: Material(
              color: s.dil == d ? r.vurgu : r.sayfa,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: s.dil == d ? r.vurgu : r.cizgi, width: 1.5),
                borderRadius: BorderRadius.circular(Kose.kart),
              ),
              child: InkWell(
                key: ValueKey('kur-dil-$d'),
                onTap: () => s.dilSec(d),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 64),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Bosluk.b16, vertical: Bosluk.b12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            dilAdlari[d]!,
                            textDirection: d == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                            style: Yazi.dilAdi.copyWith(color: s.dil == d ? r.vurguUstu : r.yazi),
                          ),
                        ),
                        if (s.dil == d) ExcludeSemantics(child: Icon(Icons.check_circle, color: r.vurguUstu)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: Bosluk.b4),
        FilledButton(
          key: const ValueKey('kurulum-devam'),
          onPressed: () => setState(() => _adim = 1),
          child: Text(s.t('continue')),
        ),
      ],
    );
  }

  Widget _eyaletAdimi(AppState s) {
    final r = Renk.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Bosluk.b12,
      children: [
        Semantics(
          header: true,
          child: Text(
            s.t('chooseState'),
            style: Yazi.baslikBuyuk.copyWith(height: 1.25),
          ),
        ),
        SolukMetin(s.t('stateHint')),
        Kart(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final e in s.katalog.eyaletler.entries)
                Semantics(
                  button: true,
                  selected: _eyalet == e.key,
                  label: e.value.ad,
                  excludeSemantics: true,
                  onTap: () => setState(() => _eyalet = e.key),
                  child: InkWell(
                    key: ValueKey('kur-eyalet-${e.key}'),
                    borderRadius: BorderRadius.circular(Kose.kontrol),
                    onTap: () => setState(() => _eyalet = e.key),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: Olcu.dokunma),
                      child: Row(
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              _eyalet == e.key ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: _eyalet == e.key ? r.vurgu : r.soluk,
                            ),
                          ),
                          const SizedBox(width: Bosluk.b12),
                          // Eyalet adları Almancadır.
                          Expanded(child: Almanca(e.value.ad, stil: Yazi.eyalet)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(Bosluk.b12),
          decoration: BoxDecoration(
            color: r.kagit,
            border: BorderDirectional(start: BorderSide(color: r.isaret, width: 4)),
          ),
          child: Text(s.t('dis'), key: const ValueKey('kurulum-uyari'), style: const TextStyle(height: 1.4)),
        ),
        FilledButton(
          key: const ValueKey('kurulum-bitir'),
          onPressed: _eyalet == null ? null : () => s.kurulumuBitir(_eyalet!),
          child: Text(s.t('startApp')),
        ),
        TextButton(
          key: const ValueKey('kurulum-geri'),
          onPressed: () => setState(() => _adim = 0),
          child: Text(s.t('prev')),
        ),
      ],
    );
  }
}
