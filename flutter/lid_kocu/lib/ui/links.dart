// LiD Koçu — dış bağlantılar (tarayıcı, e-posta).
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

Future<bool> openUrl(String url) async {
  try {
    return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (e) {
    if (kDebugMode) debugPrint('openUrl: $e');
    return false;
  }
}

Future<bool> openSupportMail() => openUrl('mailto:${AppConfig.supportEmail}?subject=${Uri.encodeComponent(AppConfig.appName)}');
