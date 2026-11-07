// LiD Koçu — Çalışma: tüm sorular ya da yanlışlarım; cevapla, doğru/yanlış + açıklama gör.
import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../state/app_controller.dart';
import '../theme.dart';
import '../widgets.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key, required this.c});
  final AppController c;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  String _filter = 'all';
  List<Question> _list = <Question>[];
  String? _listState;
  int _idx = 0;
  int? _picked;

  /// Listeyi yalnızca filtre/eyalet değişince ve "sonraki"de yeniler: yanlış bir soruyu doğru yapınca soru ekrandan kaybolmasın.
  void _rebuildList() {
    _list = widget.c.studyList(_filter);
    _listState = widget.c.stateId;
  }

  @override
  void initState() {
    super.initState();
    _rebuildList();
  }

  void _next() {
    final String? currentId = _list.isEmpty ? null : _list[_idx % _list.length].id;
    _rebuildList();
    setState(() {
      _picked = null;
      if (_list.isEmpty) {
        _idx = 0;
        return;
      }
      final int at = currentId == null ? -1 : _list.indexWhere((Question q) => q.id == currentId);
      // Yanlışlarım listesinde soru doğru yapılıp çıktıysa aynı sıra numarası bir sonraki soruyu gösterir.
      _idx = at >= 0 ? (at + 1) % _list.length : _idx % _list.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppController c = widget.c;
    final Pal p = Pal.of(context);
    final TextTheme tt = Theme.of(context).textTheme;
    if (_listState != c.stateId) {
      _rebuildList();
      _idx = 0;
      _picked = null;
    }
    final Widget filter = Row(
      children: <Widget>[
        Text(c.t('filter'), style: tt.bodyMedium?.copyWith(color: p.muted)),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
            decoration: BoxDecoration(border: Border.all(color: p.line), borderRadius: BorderRadius.circular(10)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filter,
                isExpanded: true,
                dropdownColor: p.sheet,
                items: <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: 'all', child: Text(c.t('all'))),
                  DropdownMenuItem<String>(value: 'wrongs', child: Text(c.t('wrongs'))),
                ],
                onChanged: (String? v) {
                  if (v == null) return;
                  setState(() {
                    _filter = v;
                    _idx = 0;
                    _picked = null;
                    _rebuildList();
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );

    if (_list.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[filter, const SizedBox(height: 16), Sheet(child: Text(c.t('none')))],
      );
    }
    final int idx = _idx % _list.length;
    final Question q = _list[idx];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        filter,
        const SizedBox(height: 16),
        Sheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(c.t('q', <String, Object>{'a': idx + 1, 'b': _list.length}), style: tt.bodyMedium?.copyWith(color: p.muted)),
              const SizedBox(height: 8),
              QuestionView(
                key: ValueKey<String>('study-${q.id}'),
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
              if (_picked != null) ...<Widget>[
                const SizedBox(height: 12),
                FilledButton(onPressed: _next, child: Text(c.t('next'))),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
