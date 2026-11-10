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
      spacing: 14,
      children: [
        // Başlık dört dilde: telefon dili ne olursa olsun herkes kendi dilini bulur.
        Semantics(
          header: true,
          child: Text(
            [for (final d in _kurulumDilleri) s.metin.t(d, 'chooseLang')].join(' · '),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.3),
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                key: ValueKey('kur-dil-$d'),
                onTap: () => s.dilSec(d),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 64),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            dilAdlari[d]!,
                            textDirection: d == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: s.dil == d ? r.vurguUstu : r.yazi,
                            ),
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
        const SizedBox(height: 4),
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
      spacing: 12,
      children: [
        Semantics(
          header: true,
          child: Text(
            s.t('chooseState'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.25),
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
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => setState(() => _eyalet = e.key),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Row(
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              _eyalet == e.key ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: _eyalet == e.key ? r.vurgu : r.soluk,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Eyalet adları Almancadır.
                          Expanded(child: Almanca(e.value.ad, stil: const TextStyle(fontSize: 17))),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
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
