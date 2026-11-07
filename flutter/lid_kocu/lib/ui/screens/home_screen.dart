// LiD Koçu — Ana sayfa: eyalet seçimi, ilerleme, bugünün sorusu, deneme sınavı başlat.
import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../state/app_controller.dart';
import '../premium_ui.dart';
import '../theme.dart';
import '../widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.c, required this.onGoExam});
  final AppController c;
  final VoidCallback onGoExam;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _picked;
  String? _pickedFor;

  @override
  Widget build(BuildContext context) {
    final AppController c = widget.c;
    final Pal p = Pal.of(context);
    final TextTheme tt = Theme.of(context).textTheme;
    final Question q = c.todayQuestion;
    if (_pickedFor != q.id) {
      _picked = null;
      _pickedFor = q.id;
    }
    final int total = c.pool.length;
    final int ok = c.correctCount;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        Text(c.t('hero'), style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(c.t('sub'), style: tt.bodyLarge?.copyWith(color: p.muted)),
        const SizedBox(height: 16),
        Sheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(c.t('state'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              StatePicker(c: c),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : ok / total,
                  minHeight: 10,
                  backgroundColor: p.line,
                  color: p.good,
                ),
              ),
              const SizedBox(height: 8),
              Text(c.t('learned', <String, Object>{'a': ok, 'b': total}), style: tt.bodyMedium?.copyWith(color: p.muted)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Sheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(c.t('today'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              QuestionView(
                c: c,
                q: q,
                selected: _picked,
                reveal: _picked != null,
                onPick: _picked != null
                    ? null
                    : (int i) {
                        setState(() => _picked = i);
                        c.record(q, i == q.correct);
                      },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Sheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(c.t('examInfo'), style: tt.bodyLarge),
              const SizedBox(height: 6),
              Text(examAllowanceText(c), style: tt.bodyMedium?.copyWith(color: p.muted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => startExamFlow(context, c, widget.onGoExam),
                child: Text(c.t('startExam')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Eyalet seçici (Ana sayfa ve Ayarlar).
class StatePicker extends StatelessWidget {
  const StatePicker({super.key, required this.c});
  final AppController c;

  @override
  Widget build(BuildContext context) {
    final Pal p = Pal.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
      decoration: BoxDecoration(border: Border.all(color: p.line), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: c.stateId,
          isExpanded: true,
          dropdownColor: p.sheet,
          items: <DropdownMenuItem<String>>[
            for (final StateInfo s in c.catalog.states)
              DropdownMenuItem<String>(
                value: s.id,
                child: Directionality(textDirection: TextDirection.ltr, child: Text(s.name)),
              ),
          ],
          onChanged: (String? v) {
            if (v != null) c.setStateId(v);
          },
        ),
      ),
    );
  }
}
