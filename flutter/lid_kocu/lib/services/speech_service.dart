// LiD Koçu — speech_service.dart: Almanca soruyu sesli okuma (flutter_tts, cihazın kendi metin okuma motoru; veri gönderilmez).
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract class SpeechService {
  /// Okuma sürerken true.
  ValueListenable<bool> get speaking;

  /// Metni Almanca okur. Almanca ses yoksa ya da başlatılamazsa false döner.
  Future<bool> speakGerman(String text);
  Future<void> stop();
  void dispose();
}

class FlutterTtsSpeech implements SpeechService {
  final FlutterTts _tts = FlutterTts();
  final ValueNotifier<bool> _speaking = ValueNotifier<bool>(false);
  bool _ready = false;

  @override
  ValueListenable<bool> get speaking => _speaking;

  Future<bool> _init() async {
    if (_ready) return true;
    try {
      final dynamic available = await _tts.isLanguageAvailable('de-DE');
      if (available != true && available != 1) return false;
      await _tts.setLanguage('de-DE');
      await _tts.setSpeechRate(0.45);
      _tts.setStartHandler(() => _speaking.value = true);
      _tts.setCompletionHandler(() => _speaking.value = false);
      _tts.setCancelHandler(() => _speaking.value = false);
      _tts.setErrorHandler((dynamic _) => _speaking.value = false);
      _ready = true;
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('TTS başlatılamadı: $e');
      return false;
    }
  }

  @override
  Future<bool> speakGerman(String text) async {
    if (!await _init()) return false;
    try {
      await _tts.stop();
      final dynamic r = await _tts.speak(text);
      final bool ok = r == 1 || r == true;
      if (ok) _speaking.value = true;
      return ok;
    } catch (e) {
      if (kDebugMode) debugPrint('TTS speak: $e');
      _speaking.value = false;
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _speaking.value = false;
  }

  @override
  void dispose() {
    _speaking.dispose();
  }
}
