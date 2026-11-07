// LiD Koçu — app_controller.dart: uygulama durumu (dil, eyalet, tema, ilerleme, deneme sınavı, premium).
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../core/exam.dart';
import '../core/models.dart';
import '../data/app_data.dart';
import '../services/billing_service.dart';
import '../services/save_store.dart';
import '../services/speech_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.data,
    required this.store,
    required this.billing,
    required this.speech,
    Random? random,
    DateTime Function()? clock,
    String? deviceLanguage,
  })  : _rng = random ?? Random(),
        _clock = clock ?? DateTime.now {
    final String saved = store.lang ?? deviceLanguage ?? AppConfig.defaultLanguage;
    lang = AppConfig.languages.contains(saved) ? saved : AppConfig.defaultLanguage;
    final String? savedState = store.stateId;
    stateId = (savedState != null && data.catalog.states.any((StateInfo s) => s.id == savedState)) ? savedState : AppConfig.defaultState;
    themeMode = _themeFromString(store.theme);
    results = store.results;
    examsUsed = store.examsUsed;
    premium = store.premium;
    billing.onOwnedChanged = _onOwnedChanged;
  }

  /// Gerçek servislerle denetleyici kurar (main.dart).
  static Future<AppController> create() async {
    final AppData data = await AppData.load();
    final SaveStore store = await SaveStore.open();
    final PlayBillingService billing = PlayBillingService(owned: store.premium);
    final AppController c = AppController(
      data: data,
      store: store,
      billing: billing,
      speech: FlutterTtsSpeech(),
      deviceLanguage: WidgetsBinding.instance.platformDispatcher.locale.languageCode,
    );
    unawaited(billing.start());
    return c;
  }

  final AppData data;
  final SaveStore store;
  final PremiumBilling billing;
  final SpeechService speech;
  final Random _rng;
  final DateTime Function() _clock;

  late String lang;
  late String stateId;
  late ThemeMode themeMode;
  late Map<String, bool> results;
  late int examsUsed;
  late bool premium;

  ExamSession? exam;
  Timer? _timer;

  /// Süren sınavın kalan saniyesi (yalnızca sayaç göstergesini yeniler).
  final ValueNotifier<int> secondsLeft = ValueNotifier<int>(ExamRules.minutes * 60);

  bool _disposed = false;

  // ------------------------------------------------------------------ metin
  String t(String key, [Map<String, Object> params = const <String, Object>{}]) => data.strings.t(lang, key, params);

  bool get isRtl => lang == 'ar';
  Locale get locale => Locale(lang);

  // ------------------------------------------------------------------ ayarlar
  Future<void> setLang(String v) async {
    if (!AppConfig.languages.contains(v) || v == lang) return;
    lang = v;
    notifyListeners();
    await store.setLang(v);
  }

  Future<void> setStateId(String v) async {
    if (v == stateId) return;
    stateId = v;
    notifyListeners();
    await store.setStateId(v);
  }

  Future<void> setThemeMode(ThemeMode m) async {
    if (m == themeMode) return;
    themeMode = m;
    notifyListeners();
    await store.setTheme(_themeToString(m));
  }

  static ThemeMode _themeFromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeToString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  // ------------------------------------------------------------------ çalışma / ilerleme
  Catalog get catalog => data.catalog;

  /// Çalışma havuzu: 300 genel + seçili eyaletin 10 sorusu.
  List<Question> get pool => catalog.pool(stateId);

  /// Havuzda doğru bilinen soru sayısı.
  int get correctCount => pool.where((Question q) => results[q.id] == true).length;

  /// Çalışma listesi: 'all' ya da 'wrongs' (yanlış yaptıklarım).
  List<Question> studyList(String filter) {
    final List<Question> p = pool;
    if (filter == 'wrongs') return p.where((Question q) => results[q.id] == false).toList();
    return p;
  }

  /// Bugünün sorusu: genel sorular arasında güne göre döner.
  Question get todayQuestion {
    final int day = _clock().toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    return catalog.general[day % catalog.general.length];
  }

  Future<void> record(Question q, bool correct) async {
    results[q.id] = correct;
    notifyListeners();
    await store.setResults(results);
  }

  /// Doğru/yanlış kayıtlarını siler. Deneme sınavı hakkı ve Premium etkilenmez (ücretsiz hak sıfırlanmasın).
  Future<void> resetProgress() async {
    results = <String, bool>{};
    notifyListeners();
    await store.setResults(results);
  }

  // ------------------------------------------------------------------ deneme sınavı
  bool get canStartExam => mayStartExam(premium: premium, examsUsed: examsUsed);

  /// Kalan ücretsiz deneme (premium: null = sınırsız).
  int? get examsLeft => freeExamsLeft(premium: premium, examsUsed: examsUsed);

  /// Yeni sınav başlatır. Hak yoksa false döner (arayüz Premium teklifini gösterir).
  bool startExam() {
    if (!canStartExam) return false;
    final List<Question> qs = pickExam(catalog.general, catalog.stateById(stateId).questions, _rng);
    final DateTime end = _clock().add(const Duration(minutes: ExamRules.minutes));
    exam = ExamSession(questions: qs, endsAt: end);
    secondsLeft.value = exam!.secondsLeft(_clock());
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer _) => _tick());
    notifyListeners();
    return true;
  }

  void _tick() {
    final ExamSession? e = exam;
    if (e == null || e.over || _disposed) {
      _timer?.cancel();
      return;
    }
    final int left = e.secondsLeft(_clock());
    secondsLeft.value = left;
    if (left <= 0) finishExam(timedOut: true);
  }

  void answerExam(int answer) {
    final ExamSession? e = exam;
    if (e == null || e.over) return;
    e.answers[e.index] = answer;
    if (e.index < e.questions.length - 1) e.index++;
    notifyListeners();
  }

  void goToExamQuestion(int i) {
    final ExamSession? e = exam;
    if (e == null || i < 0 || i >= e.questions.length) return;
    e.index = i;
    notifyListeners();
  }

  /// Sınavı bitirir: cevaplanan sorular ilerlemeye işlenir, ücretsiz hak bir azalır.
  Future<void> finishExam({bool timedOut = false}) async {
    final ExamSession? e = exam;
    if (e == null || e.over) return;
    e.over = true;
    e.timedOut = timedOut;
    e.index = 0;
    _timer?.cancel();
    _timer = null;
    for (int i = 0; i < e.questions.length; i++) {
      final int? a = e.answers[i];
      if (a != null) results[e.questions[i].id] = a == e.questions[i].correct;
    }
    examsUsed++;
    notifyListeners();
    await store.setResults(results);
    await store.setExamsUsed(examsUsed);
  }

  /// Biten sınavın ekranını kapatır.
  void clearExam() {
    exam = null;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  // ------------------------------------------------------------------ premium
  void _onOwnedChanged(bool owned) {
    premium = owned;
    notifyListeners();
    store.setPremium(owned);
  }

  Future<PurchaseOutcome> buyPremium() async {
    final PurchaseOutcome r = await billing.purchase();
    if (r == PurchaseOutcome.purchased && !premium) _onOwnedChanged(true);
    return r;
  }

  /// true = geri yüklendi, false = bu hesapta satın alma yok, null = Play'e ulaşılamadı.
  Future<bool?> restorePremium() async {
    final bool? r = await billing.restore();
    if (r != null && r != premium) _onOwnedChanged(r);
    return r;
  }

  // ------------------------------------------------------------------ sesli okuma
  /// Soruyu (ve metin seçenekleriyle birlikte) Almanca okur. Almanca ses yoksa false.
  Future<bool> speak(Question q) {
    const List<String> letters = <String>['A', 'B', 'C', 'D'];
    final StringBuffer b = StringBuffer(q.de);
    final bool pictureOptions = q.options.every((String o) => o.startsWith('Bild '));
    if (!pictureOptions) {
      for (int i = 0; i < q.options.length; i++) {
        b.write(' ${letters[i]}: ${q.options[i]}.');
      }
    }
    return speech.speakGerman(b.toString());
  }

  Future<void> stopSpeaking() => speech.stop();

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    secondsLeft.dispose();
    billing.dispose();
    speech.dispose();
    super.dispose();
  }
}
