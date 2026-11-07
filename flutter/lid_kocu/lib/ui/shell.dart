// LiD Koçu — ana iskelet: üstte marka + dil düğmeleri, altta Ana sayfa / Çalış / Deneme sınavı / Ayarlar.
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../state/app_controller.dart';
import 'screens/exam_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/study_screen.dart';
import 'theme.dart';

class Shell extends StatefulWidget {
  const Shell({super.key, required this.c});
  final AppController c;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  void _goExam() => setState(() => _tab = 2);

  @override
  Widget build(BuildContext context) {
    final AppController c = widget.c;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: <Widget>[
                _Header(c: c),
                Expanded(
                  child: IndexedStack(
                    index: _tab,
                    children: <Widget>[
                      HomeScreen(c: c, onGoExam: _goExam),
                      StudyScreen(c: c),
                      ExamScreen(c: c),
                      SettingsScreen(c: c),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (int i) => setState(() => _tab = i),
        destinations: <NavigationDestination>[
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: c.t('home')),
          NavigationDestination(icon: const Icon(Icons.menu_book_outlined), selectedIcon: const Icon(Icons.menu_book), label: c.t('study')),
          NavigationDestination(icon: const Icon(Icons.quiz_outlined), selectedIcon: const Icon(Icons.quiz), label: c.t('exam')),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: c.t('settings')),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.c});
  final AppController c;

  @override
  Widget build(BuildContext context) {
    final Pal p = Pal.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: <Widget>[
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: <Widget>[
                const Text('LiD ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(color: p.mark, borderRadius: BorderRadius.circular(4)),
                  child: Text('Koçu', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: p.onMark)),
                ),
              ],
            ),
          ),
          const Spacer(),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: <Widget>[
                for (final String l in AppConfig.languages)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: _LangButton(label: AppConfig.languageLabels[l]!, selected: c.lang == l, onTap: () => c.setLang(l)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Pal p = Pal.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? p.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: selected ? p.ink : p.line),
          ),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? p.paper : p.ink)),
        ),
      ),
    );
  }
}
