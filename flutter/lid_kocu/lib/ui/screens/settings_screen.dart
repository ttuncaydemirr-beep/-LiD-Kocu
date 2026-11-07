// LiD Koçu — Ayarlar: dil, eyalet, görünüm, Premium, gizlilik, destek, ilerlemeyi sıfırla, hakkında.
import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../links.dart';
import '../premium_ui.dart';
import '../theme.dart';
import '../widgets.dart';
import '../../state/app_controller.dart';
import 'home_screen.dart' show StatePicker;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.c});
  final AppController c;

  static String _formatDate(String iso) {
    final List<String> p = iso.split('-');
    return p.length == 3 ? '${p[2]}.${p[1]}.${p[0]}' : iso;
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        content: Text(c.t('resetAsk')),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(c.t('cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(c.t('reset')),
          ),
        ],
      ),
    );
    if (yes == true) {
      await c.resetProgress();
      messenger.showSnackBar(SnackBar(content: Text(c.t('ok'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Pal p = Pal.of(context);
    final TextTheme tt = Theme.of(context).textTheme;
    final TextStyle? muted = tt.bodyMedium?.copyWith(color: p.muted);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        PremiumPanel(c: c),
        const SizedBox(height: 16),
        Sheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(c.t('language'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final String l in AppConfig.languages)
                    ChoiceChip(
                      label: Text(AppConfig.languageNames[l]!),
                      selected: c.lang == l,
                      onSelected: (bool _) => c.setLang(l),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(c.t('state'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              StatePicker(c: c),
              const SizedBox(height: 16),
              Text(c.t('theme'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: <ButtonSegment<ThemeMode>>[
                  ButtonSegment<ThemeMode>(value: ThemeMode.system, label: Text(c.t('themeSystem'))),
                  ButtonSegment<ThemeMode>(value: ThemeMode.light, label: Text(c.t('themeLight'))),
                  ButtonSegment<ThemeMode>(value: ThemeMode.dark, label: Text(c.t('themeDark'))),
                ],
                selected: <ThemeMode>{c.themeMode},
                onSelectionChanged: (Set<ThemeMode> s) => c.setThemeMode(s.first),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Sheet(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: <Widget>[
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(c.t('privacy')),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => openUrl(AppConfig.privacyUrl),
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: Text(c.t('contactMail')),
                subtitle: Directionality(textDirection: TextDirection.ltr, child: Text(AppConfig.supportEmail)),
                onTap: openSupportMail,
              ),
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: Text(c.t('resetProgress')),
                onTap: () => _confirmReset(context),
              ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Sheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(c.t('about'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(c.t('dis'), style: muted),
              const SizedBox(height: 6),
              Text(c.t('answersNote'), style: muted),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => openUrl(AppConfig.officialCatalogUrl),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(c.t('src'), style: tt.bodyMedium?.copyWith(color: p.accent, decoration: TextDecoration.underline)),
                ),
              ),
              Text(c.t('ver', <String, Object>{'d': _formatDate(c.catalog.stand)}), style: muted),
              const SizedBox(height: 4),
              Text(c.t('version', <String, Object>{'v': AppConfig.appVersion}), style: muted),
            ],
          ),
        ),
      ],
    );
  }
}
