// LiD Koçu — Premium arayüzü: ücretsiz hak bitince teklif penceresi, Ayarlar'daki Premium paneli, sınav başlatma akışı.
import 'package:flutter/material.dart';

import '../core/exam.dart';
import '../services/billing_service.dart';
import '../state/app_controller.dart';
import 'theme.dart';
import 'widgets.dart';

String outcomeMessage(AppController c, PurchaseOutcome o) {
  switch (o) {
    case PurchaseOutcome.purchased:
      return c.t('premiumOn');
    case PurchaseOutcome.pending:
      return c.t('payPending');
    case PurchaseOutcome.cancelled:
      return c.t('payCancelled');
    case PurchaseOutcome.failed:
      return c.t('payFailed');
    case PurchaseOutcome.unavailable:
      return c.t('payUnavailable');
  }
}

/// Ücretsiz deneme hakkı bitince gösterilir.
Future<void> showPaywall(BuildContext context, AppController c) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final bool? buy = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: Text(c.t('limitTitle')),
      content: Text(c.t('limitBody', <String, Object>{'n': ExamRules.freeExams})),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(c.t('cancel'))),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(c.billing.price == null ? c.t('buyPremium') : c.t('buyPremiumPrice', <String, Object>{'p': c.billing.price!})),
        ),
      ],
    ),
  );
  if (buy == true) {
    final PurchaseOutcome r = await c.buyPremium();
    messenger.showSnackBar(SnackBar(content: Text(outcomeMessage(c, r))));
  }
}

/// Yeni deneme sınavı başlatır; hak yoksa Premium teklifini gösterir. Başarılıysa [onStarted] çağrılır.
Future<void> startExamFlow(BuildContext context, AppController c, VoidCallback onStarted) async {
  final ExamSession? running = c.exam;
  if (running != null && !running.over) {
    onStarted();
    return;
  }
  if (!c.startExam()) {
    await showPaywall(context, c);
    return;
  }
  onStarted();
}

/// Kalan ücretsiz deneme / sınırsız bilgisi.
String examAllowanceText(AppController c) {
  final int? left = c.examsLeft;
  return left == null ? c.t('examsUnlimited') : c.t('examsFree', <String, Object>{'n': left});
}

/// Ayarlar'daki Premium paneli.
class PremiumPanel extends StatefulWidget {
  const PremiumPanel({super.key, required this.c});
  final AppController c;

  @override
  State<PremiumPanel> createState() => _PremiumPanelState();
}

class _PremiumPanelState extends State<PremiumPanel> {
  bool _busy = false;
  String? _message;

  Future<void> _buy() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final PurchaseOutcome r = await widget.c.buyPremium();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = outcomeMessage(widget.c, r);
    });
  }

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final bool? r = await widget.c.restorePremium();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = r == null ? widget.c.t('restoreFailed') : (r ? widget.c.t('restoredOk') : widget.c.t('restoredNone'));
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppController c = widget.c;
    final Pal p = Pal.of(context);
    final TextTheme tt = Theme.of(context).textTheme;
    return Sheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(c.premium ? Icons.workspace_premium : Icons.lock_open, color: p.accent),
              const SizedBox(width: 8),
              Text(c.t('premium'), style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Text(c.t('premiumDesc'), style: tt.bodyMedium?.copyWith(color: p.muted)),
          const SizedBox(height: 8),
          Text(examAllowanceText(c), style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (c.premium)
            Tag(c.t('premiumOn'), background: p.goodBg, foreground: p.good, icon: Icons.check_circle)
          else ...<Widget>[
            FilledButton(
              onPressed: _busy ? null : _buy,
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(c.billing.price == null ? c.t('buyPremium') : c.t('buyPremiumPrice', <String, Object>{'p': c.billing.price!})),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _busy ? null : _restore, child: Text(c.t('restore'))),
          ],
          if (_message != null) ...<Widget>[
            const SizedBox(height: 10),
            Semantics(liveRegion: true, child: Text(_message!, style: tt.bodyMedium)),
          ],
        ],
      ),
    );
  }
}
