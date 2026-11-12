// LiD Koçu — Firebase Analytics ve Remote Config.
//  - android/app/google-services.json yoksa Firebase.initializeApp başarısız olur: uygulama çökmeden devam eder,
//    olaylar sessizce boşa düşer, Remote Config yerine koddaki varsayılanlar (uzakVarsayilan) kullanılır.
//  - Testlerde ve Play olmayan ortamda baslat() çağrılmaz; eklentilere hiç dokunulmaz.
import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'reklam_karar.dart';

class Olcum {
  // Geç oluşturulur: Firebase hazır olmadan örneklere erişilmez.
  late final FirebaseAnalytics _fa = FirebaseAnalytics.instance;
  late final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;

  bool _hazir = false;
  bool _uzakHazir = false;
  Future<void>? _baslama;

  /// Remote Config değerleri geldiğinde (veya değiştiğinde) çağrılır.
  VoidCallback? uzakGeldi;

  bool get hazir => _hazir;

  /// Beklenmeden (unawaited) çağrılabilir; ilk ekranı bekletmez.
  Future<void> baslat() => _baslama ??= _baslat();

  Future<void> _baslat() async {
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 10));
      _hazir = true;
      uzakGeldi?.call(); // Analytics hazır: user property yazılabilir
    } catch (e) {
      if (kDebugMode) debugPrint('Firebase kapalı (google-services.json yok mu?): $e');
      return;
    }
    try {
      await _rc.setDefaults(uzakVarsayilan);
      await _rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode ? const Duration(minutes: 5) : const Duration(hours: 12),
      ));
      _uzakHazir = true;
      await _rc.fetchAndActivate().timeout(const Duration(seconds: 15));
    } catch (e) {
      if (kDebugMode) debugPrint('Remote Config: $e');
    }
    // Yeni değerler (getirilemediyse önceki oturumda etkinleştirilenler) artık okunabilir.
    if (_uzakHazir) uzakGeldi?.call();
  }

  /// Remote Config bayrağı; Firebase yoksa koddaki varsayılan.
  bool bayrak(String anahtar) {
    if (_uzakHazir) {
      try {
        return _rc.getBool(anahtar);
      } catch (_) {}
    }
    final v = uzakVarsayilan[anahtar];
    return v is bool ? v : false;
  }

  /// Remote Config sayısı; Firebase yoksa koddaki varsayılan.
  double sayi(String anahtar) {
    if (_uzakHazir) {
      try {
        return _rc.getDouble(anahtar);
      } catch (_) {}
    }
    final v = uzakVarsayilan[anahtar];
    return v is num ? v.toDouble() : 0;
  }

  /// Analytics olayı. Firebase yoksa sessizce boşa düşer.
  void olay(String ad, [Map<String, Object>? parametreler]) {
    if (!_hazir) return;
    unawaited(() async {
      try {
        await _fa.logEvent(name: ad, parameters: parametreler);
      } catch (e) {
        if (kDebugMode) debugPrint('Analytics $ad: $e');
      }
    }());
  }

  /// Analytics user property. Firebase yoksa sessizce boşa düşer.
  void ozellik(String ad, String deger) {
    if (!_hazir) return;
    unawaited(() async {
      try {
        await _fa.setUserProperty(name: ad, value: deger);
      } catch (e) {
        if (kDebugMode) debugPrint('Analytics özellik $ad: $e');
      }
    }());
  }
}
