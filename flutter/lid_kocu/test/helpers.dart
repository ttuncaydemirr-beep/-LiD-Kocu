import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lid_kocu/data/app_data.dart';
import 'package:lid_kocu/services/billing_service.dart';
import 'package:lid_kocu/services/speech_service.dart';

/// Gömülü JSON verisini yükler (flutter test ortamında rootBundle).
Future<AppData> loadData() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  return AppData.load();
}

class FakeBilling implements PremiumBilling {
  FakeBilling({this.owned = false});

  @override
  bool owned;
  @override
  bool available = true;
  @override
  String? price = '79,99';
  @override
  void Function(bool owned)? onOwnedChanged;

  PurchaseOutcome nextOutcome = PurchaseOutcome.purchased;
  bool? restoreResult;
  int purchaseCalls = 0;

  @override
  Future<void> start() async {}

  @override
  Future<PurchaseOutcome> purchase() async {
    purchaseCalls++;
    if (nextOutcome == PurchaseOutcome.purchased) {
      owned = true;
      onOwnedChanged?.call(true);
    }
    return nextOutcome;
  }

  @override
  Future<bool?> restore() async {
    final bool? r = restoreResult;
    if (r != null && r != owned) {
      owned = r;
      onOwnedChanged?.call(r);
    }
    return r;
  }

  @override
  void dispose() {}
}

class FakeSpeech implements SpeechService {
  final ValueNotifier<bool> _speaking = ValueNotifier<bool>(false);
  final List<String> spoken = <String>[];
  bool germanAvailable = true;

  @override
  ValueListenable<bool> get speaking => _speaking;

  @override
  Future<bool> speakGerman(String text) async {
    if (!germanAvailable) return false;
    spoken.add(text);
    return true;
  }

  @override
  Future<void> stop() async {}

  @override
  void dispose() => _speaking.dispose();
}
