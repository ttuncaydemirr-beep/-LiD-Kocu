// LiD Koçu — Deneme sınavı: 33 soru, 60 dakika, soru şeridi, bitirme onayı, sonuç ve hata incelemesi.
import 'package:flutter/material.dart';

import '../../core/exam.dart';
import '../../state/app_controller.dart';
import '../premium_ui.dart';
import '../theme.dart';
import '../widgets.dart';

class ExamScreen extends StatelessWidget {
  const ExamScreen({super.key, required this.c});
  final AppController c;

  @override
  Widget build(BuildContext context) {
    final ExamSession? e = c.exam;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: e == null ? _intro(context) : (e.over ? _result(context, e) : _running(context, e)),
    );
  }

  // ------------------------------------------------------------------ giriş
  List<Widget> _intro(BuildContext context) {
    final Pal p = Pal.of(context);
    final TextTheme tt = Theme.of(context).textTheme;
    return <Widget>[
      Sheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(c.t('exam'), style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(c.t('examInfo'), style: tt.bodyLarge),
            const SizedBox(height: 6),
            Text(examAllowanceText(c), style: tt.bodyMedium?.copyWith(color: p.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => startExamFlow(context, c, () {}), child: Text(c.t('startExam'))),
          ],
        ),
      ),
    ];
  }

  // ------------------------------------------------------------------ süren sınav
  String _clock(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  Future<void> _confirmFinish(BuildContext context, ExamSession e) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        content: Text(c.t('finishAsk', <String, Object>{'n': e.unanswered})),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(c.t('continueExam'))),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(c.t('finish')),
          ),
        ],
      ),
    );
    if (yes == true) await c.finishExam();
  }

  List<Widget> _running(BuildContext context, ExamSession e) {
    final Pal p = Pal.of(context);
    final TextTheme tt = Theme.of(context).textTheme;
    final int n = e.questions.length;
    return <Widget>[
      Row(
        children: <Widget>[
          Expanded(child: Text(c.t('q', <String, Object>{'a': e.index + 1, 'b': n}), style: tt.bodyLarge?.copyWith(color: p.muted))),
          ValueListenableBuilder<int>(
            valueListenable: c.secondsLeft,
            builder: (BuildContext context, int s, Widget? _) => Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                _clock(s),
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: s <= 300 ? p.bad : p.ink, fontFeatures: const <FontFeature>[FontFeature.tabularFigures()]),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _strip(context, e),
      const SizedBox(height: 12),
      Sheet(
        child: QuestionView(
          key: ValueKey<String>('exam-${e.index}-${e.questions[e.index].id}'),
          c: c,
          q: e.questions[e.index],
          selected: e.answers[e.index],
          onPick: c.answerExam,
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: <Widget>[
          Expanded(child: OutlinedButton(onPressed: e.index > 0 ? () => c.goToExamQuestion(e.index - 1) : null, child: Text(c.t('prev')))),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton(onPressed: e.index < n - 1 ? () => c.goToExamQuestion(e.index + 1) : null, child: Text(c.t('nextQ')))),
        ],
      ),
      const SizedBox(height: 12),
      FilledButton(onPressed: () => _confirmFinish(context, e), child: Text(c.t('finish'))),
      if (e.unanswered > 0) ...<Widget>[
        const SizedBox(height: 8),
        Text(c.t('left', <String, Object>{'n': e.unanswered}), style: tt.bodyMedium?.copyWith(color: p.muted)),
      ],
    ];
  }

  // ------------------------------------------------------------------ sonuç + inceleme
  List<Widget> _result(BuildContext context, ExamSession e) {
    final Pal p = Pal.of(context);
    final TextTheme tt = Theme.of(context).textTheme;
    final int score = e.score;
    final bool pass = e.passed;
    return <Widget>[
      Sheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Tag(
              pass ? c.t('passed') : c.t('failed'),
              background: pass ? p.goodBg : p.badBg,
              foreground: pass ? p.good : p.bad,
              icon: pass ? Icons.check_circle : Icons.cancel,
            ),
            if (e.timedOut) ...<Widget>[const SizedBox(height: 8), Text(c.t('timeUp'), style: tt.bodyMedium?.copyWith(color: p.muted))],
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text('$score / ${ExamRules.total}', style: tt.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 4),
            Text(c.t('score', <String, Object>{'n': score}), style: tt.bodyLarge),
            const SizedBox(height: 4),
            Text(examAllowanceText(c), style: tt.bodyMedium?.copyWith(color: p.muted)),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => startExamFlow(context, c, () {}), child: Text(c.t('again'))),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(c.t('review'), style: tt.bodyMedium?.copyWith(color: p.muted)),
      const SizedBox(height: 8),
      _strip(context, e),
      const SizedBox(height: 12),
      Sheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(c.t('q', <String, Object>{'a': e.index + 1, 'b': e.questions.length}), style: tt.bodyMedium?.copyWith(color: p.muted)),
            const SizedBox(height: 8),
            QuestionView(
              key: ValueKey<String>('review-${e.index}-${e.questions[e.index].id}'),
              c: c,
              q: e.questions[e.index],
              selected: e.answers[e.index],
              reveal: true,
            ),
          ],
        ),
      ),
    ];
  }

  // ------------------------------------------------------------------ soru şeridi (1..33)
  Widget _strip(BuildContext context, ExamSession e) {
    final Pal p = Pal.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: <Widget>[
          for (int i = 0; i < e.questions.length; i++)
            _stripCell(p, e, i),
        ],
      ),
    );
  }

  Widget _stripCell(Pal p, ExamSession e, int i) {
    Color bg = p.sheet;
    Color fg = p.ink;
    Color border = p.line;
    if (e.over) {
      final bool ok = e.answers[i] == e.questions[i].correct;
      bg = ok ? p.goodBg : p.badBg;
      fg = ok ? p.good : p.bad;
      border = fg;
    } else if (e.answers[i] != null) {
      bg = p.accent.withValues(alpha: 0.16);
    }
    final bool current = i == e.index;
    return Semantics(
      button: true,
      label: '${i + 1}',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => c.goToExamQuestion(i),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: current ? p.accent : border, width: current ? 3 : 1),
          ),
          child: Text('${i + 1}', style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
