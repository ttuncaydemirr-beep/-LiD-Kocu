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
    final stil = TextStyle(fontSize: 14, color: r.soluk, height: 1.4);
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: r.cizgi))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          Text(s.t('dis'), style: stil),
          Text(s.t('imgNote'), style: stil),
          _Baglanti(metin: s.t('src'), url: kaynakUrl),
          _Baglanti(metin: s.t('testCenter'), url: testMerkeziUrl),
          Text(s.t('ver', {'d': s.katalog.surum}), style: stil),
          SelectableText(s.t('sup', {'m': destekEposta}), style: stil),
        ],
      ),
    );
  }
}

class _Baglanti extends StatelessWidget {
  const _Baglanti({required this.metin, required this.url});
  final String metin;
  final String url;

  @override
  Widget build(BuildContext context) {
    final r = Renk.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => _ac(url),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              metin,
              style: TextStyle(fontSize: 14, color: r.vurgu, decoration: TextDecoration.underline, height: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}
