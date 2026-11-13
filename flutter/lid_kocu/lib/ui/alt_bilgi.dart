// Alt bilgi: resmî değil uyarısı, kaynak bağlantıları, sürüm, destek.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state.dart';
import 'durum.dart';
import 'tema.dart';

Future<void> _ac(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

class AltBilgi extends StatelessWidget {
  const AltBilgi({super.key});

  @override
  Widget build(BuildContext context) {
    final s = DurumKapsami.of(context);
    final r = Renk.of(context);
    final stil = Yazi.altBilgi.copyWith(color: r.soluk);
    return Container(
      padding: const EdgeInsets.only(top: Bosluk.b12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: r.cizgi))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Bosluk.b6,
        children: [
          Text(s.t('dis'), style: stil),
          Text(s.t('imgNote'), style: stil),
          _Baglanti(metin: s.t('src'), url: kaynakUrl),
          _Baglanti(metin: s.t('testCenter'), url: testMerkeziUrl),
          // AB/AEA/İsviçre: UMP gerekli görürse (Premium'da reklam olmadığı için gösterilmez).
          if (!s.premium && s.reklam.gizlilikGerekli)
            _Baglanti(
              key: const ValueKey('gizlilik-secenekleri'),
              metin: s.t('privacyOptions'),
              onTap: s.reklam.gizlilikSecenekleri,
            ),
          Text(s.t('ver', {'d': s.katalog.surum}), style: stil),
          SelectableText(s.t('sup', {'m': destekEposta}), style: stil),
        ],
      ),
    );
  }
}

class _Baglanti extends StatelessWidget {
  const _Baglanti({super.key, required this.metin, this.url, this.onTap});
  final String metin;
  final String? url;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = Renk.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap ?? () => _ac(url ?? ''),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Olcu.dokunma),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              metin,
              style: Yazi.altBilgi.copyWith(color: r.vurgu, decoration: TextDecoration.underline),
            ),
          ),
        ),
      ),
    );
  }
}
