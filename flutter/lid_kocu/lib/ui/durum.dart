// Uygulama durumunu ağaca dağıtır (ek paket yok).
import 'package:flutter/widgets.dart';

import '../state.dart';

class DurumKapsami extends InheritedNotifier<AppState> {
  const DurumKapsami({super.key, required AppState state, required super.child}) : super(notifier: state);

  /// build içinde kullanın: durum değişince widget yeniden kurulur.
  static AppState of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<DurumKapsami>();
    assert(w != null, 'DurumKapsami bulunamadı');
    return w!.notifier!;
  }

  /// Olay işleyicilerinde kullanın: bağımlılık oluşturmaz.
  static AppState oku(BuildContext context) {
    final w = context.getInheritedWidgetOfExactType<DurumKapsami>();
    assert(w != null, 'DurumKapsami bulunamadı');
    return w!.notifier!;
  }
}
