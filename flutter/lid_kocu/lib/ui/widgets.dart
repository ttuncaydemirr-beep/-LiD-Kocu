// LiD Koçu — ortak arayüz parçaları: sayfa kutusu, etiket, Almanca metin, soru görünümü.
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../core/models.dart';
import '../state/app_controller.dart';
import 'links.dart';
import 'theme.dart';

/// Beyaz "sayfa" kutusu.
class Sheet extends StatelessWidget {
  const Sheet({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final Pal p = Pal.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: p.sheet,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.line),
      ),
      child: child,
    );
  }
}

/// Küçük etiket (ör. "güncel olabilir", "Geçtin").
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.background, this.foreground, this.icon});
  final String text;
  final Color? background;
  final Color? foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Pal p = Pal.of(context);
    final Color fg = foreground ?? p.onMark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background ?? p.mark, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[Icon(icon, size: 16, color: fg), const SizedBox(width: 6)],
          Flexible(child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13))),
        ],
      ),
    );
  }
}

/// Almanca metin: arayüz sağdan sola (Arapça) olsa bile soldan sağa ve sola yaslı gösterilir.
class DeText extends StatelessWidget {
  const DeText(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: double.infinity,
        child: Text(text, textAlign: TextAlign.left, style: style),
      ),
    );
  }
}

enum OptionState { idle, selected, correct, wrong }

/// Tek cevap seçeneği: Almanca metin, çeviri ve (resimli sorularda) resim açıklaması.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.index,
    required this.de,
    this.translated,
    this.pictureDe,
    this.pictureTr,
    this.state = OptionState.idle,
    this.onTap,
  });

  final int index;
  final String de;
  final String? translated;
  final String? pictureDe;
  final String? pictureTr;
  final OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Pal p = Pal.of(context);
    Color bg = p.sheet;
    Color border = p.line;
    double width = 1;
    IconData? icon;
    Color? iconColor;
    switch (state) {
      case OptionState.idle:
        break;
      case OptionState.selected:
        border = p.accent;
        width = 2;
      case OptionState.correct:
        bg = p.goodBg;
        border = p.good;
        width = 2;
        icon = Icons.check_circle;
        iconColor = p.good;
      case OptionState.wrong:
        bg = p.badBg;
        border = p.bad;
        width = 2;
        icon = Icons.cancel;
        iconColor = p.bad;
    }
    final TextStyle? small = Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.muted);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: border, width: width)),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: border)),
                  child: Text(String.fromCharCode(65 + index), style: TextStyle(fontWeight: FontWeight.w700, color: p.ink)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      DeText(de, style: Theme.of(context).textTheme.bodyLarge),
                      if (translated != null) ...<Widget>[const SizedBox(height: 4), Text(translated!, style: small)],
                      if (pictureDe != null) ...<Widget>[const SizedBox(height: 6), DeText(pictureDe!, style: small)],
                      if (pictureTr != null) ...<Widget>[const SizedBox(height: 4), Text(pictureTr!, style: small)],
                    ],
                  ),
                ),
                if (icon != null) ...<Widget>[const SizedBox(width: 8), Icon(icon, color: iconColor)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Almanca sesli okuma düğmesi.
class SpeakButton extends StatelessWidget {
  const SpeakButton({super.key, required this.c, required this.q});
  final AppController c;
  final Question q;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: c.speech.speaking,
      builder: (BuildContext context, bool speaking, Widget? _) {
        return IconButton.filledTonal(
          tooltip: speaking ? c.t('stop') : c.t('listen'),
          icon: Icon(speaking ? Icons.stop : Icons.volume_up),
          onPressed: () async {
            final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
            if (speaking) {
              await c.stopSpeaking();
              return;
            }
            final bool ok = await c.speak(q);
            if (!ok) {
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(c.t('ttsFail'))));
            }
          },
        );
      },
    );
  }
}

/// Soru görünümü. Üç kullanım:
///  - çalışma: seçince [reveal] açılır (doğru/yanlış + açıklama),
///  - sınav: [reveal] kapalı, yalnızca [selected] vurgulanır,
///  - inceleme: [reveal] açık, [onPick] boş.
class QuestionView extends StatelessWidget {
  const QuestionView({
    super.key,
    required this.c,
    required this.q,
    this.selected,
    this.reveal = false,
    this.onPick,
  });

  final AppController c;
  final Question q;
  final int? selected;
  final bool reveal;
  final ValueChanged<int>? onPick;

  @override
  Widget build(BuildContext context) {
    final Pal p = Pal.of(context);
    final TextTheme tt = Theme.of(context).textTheme;
    final bool isDe = c.lang == 'de';
    final QuestionText? tr = isDe ? null : c.data.translations.of(q.id, c.lang);
    final QuestionText? de = c.data.translations.german(q.id);
    final List<String>? g = de?.g;
    final bool onePicture = g != null && g.length == 1;
    final bool fourPictures = g != null && g.length == 4;
    final List<String>? gTr = tr?.g;
    final String? explanation = isDe ? de?.x : tr?.x;
    final String metaLabel = q.isState ? c.t('stateQ', <String, Object>{'s': c.catalog.stateById(q.stateId!).name}) : c.t('generalQ');

    final List<Widget> children = <Widget>[
      Row(
        children: <Widget>[
          Expanded(child: Text(metaLabel, style: tt.bodySmall?.copyWith(color: p.muted))),
          SpeakButton(c: c, q: q),
        ],
      ),
      DeText(q.de, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      if (tr?.q != null) ...<Widget>[const SizedBox(height: 8), Text(tr!.q!, style: tt.bodyLarge)] else if (!isDe) ...<Widget>[
        const SizedBox(height: 8),
        Text(c.t('noTr'), style: tt.bodyMedium?.copyWith(color: p.muted)),
      ],
      if (g != null) ...<Widget>[
        const SizedBox(height: 8),
        Text(c.t('noImg'), style: tt.bodyMedium?.copyWith(color: p.muted)),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => openUrl(AppConfig.officialCatalogUrl),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(c.t('pictureLink')),
          ),
        ),
      ],
      if (onePicture) ...<Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: p.line), borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DeText(g[0], style: tt.bodyMedium),
              if (gTr != null && gTr.isNotEmpty) ...<Widget>[const SizedBox(height: 6), Text(gTr[0], style: tt.bodyMedium?.copyWith(color: p.muted))],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
      if (q.dated) ...<Widget>[
        const SizedBox(height: 8),
        Align(alignment: AlignmentDirectional.centerStart, child: Tag(c.t('dated'), icon: Icons.update)),
      ],
      const SizedBox(height: 12),
      for (int i = 0; i < q.options.length; i++)
        OptionTile(
          index: i,
          de: q.options[i],
          translated: tr?.o?[i],
          pictureDe: fourPictures ? g[i] : null,
          pictureTr: fourPictures ? (gTr != null && gTr.length == 4 ? gTr[i] : null) : null,
          state: _stateOf(i),
          onTap: onPick == null ? null : () => onPick!(i),
        ),
    ];

    if (reveal) {
      if (selected == null) {
        children.add(Text(c.t('empty'), style: tt.bodyMedium?.copyWith(color: p.muted)));
      } else {
        final bool ok = selected == q.correct;
        children.add(Semantics(
          liveRegion: true,
          child: Text(ok ? c.t('right') : c.t('wrong'), style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: ok ? p.good : p.bad)),
        ));
      }
      if (explanation != null && explanation.isNotEmpty) {
        children.add(const SizedBox(height: 8));
        children.add(Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.paper,
            border: BorderDirectional(start: BorderSide(color: p.mark, width: 4)),
          ),
          child: Text(explanation, style: tt.bodyMedium),
        ));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  OptionState _stateOf(int i) {
    if (reveal) {
      if (i == q.correct) return OptionState.correct;
      if (i == selected) return OptionState.wrong;
      return OptionState.idle;
    }
    return i == selected ? OptionState.selected : OptionState.idle;
  }
}
