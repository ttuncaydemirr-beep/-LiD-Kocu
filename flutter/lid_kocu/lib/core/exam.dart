// LiD Koçu — sınav mantığı (saf Dart, platform bağımsız): soru seçimi, puanlama, süre, ücretsiz deneme sınırı.
import 'dart:math';

import 'models.dart';

class ExamRules {
  ExamRules._();

  static const int generalCount = 30;
  static const int stateCount = 3;
  static const int total = generalCount + stateCount; // 33
  static const int passMark = 17; // geçmek için en az 17 doğru
  static const int minutes = 60;

  /// Premium olmayanlar için ücretsiz deneme sınavı hakkı.
  static const int freeExams = 2;
}

/// 30 genel + seçilen eyaletten 3 soru = 33 soru; tekrarsız, karışık sırada.
List<Question> pickExam(List<Question> general, List<Question> stateQuestions, Random rng) {
  if (general.length < ExamRules.generalCount || stateQuestions.length < ExamRules.stateCount) {
    throw ArgumentError('Yeterli soru yok: genel ${general.length}, eyalet ${stateQuestions.length}');
  }
  final List<Question> g = List<Question>.of(general)..shuffle(rng);
  final List<Question> s = List<Question>.of(stateQuestions)..shuffle(rng);
  final List<Question> picked = <Question>[...g.take(ExamRules.generalCount), ...s.take(ExamRules.stateCount)]..shuffle(rng);
  return picked;
}

int scoreOf(List<Question> questions, List<int?> answers) {
  int n = 0;
  for (int i = 0; i < questions.length; i++) {
    if (answers[i] == questions[i].correct) n++;
  }
  return n;
}

bool isPassed(int score) => score >= ExamRules.passMark;

/// Premium ya da ücretsiz hak kaldıysa yeni deneme sınavı başlatılabilir.
bool mayStartExam({required bool premium, required int examsUsed}) => premium || examsUsed < ExamRules.freeExams;

/// Kalan ücretsiz deneme sayısı (premium için null = sınırsız).
int? freeExamsLeft({required bool premium, required int examsUsed}) {
  if (premium) return null;
  final int left = ExamRules.freeExams - examsUsed;
  return left < 0 ? 0 : left;
}

/// Süren ya da biten bir deneme sınavı.
class ExamSession {
  ExamSession({required this.questions, required this.endsAt})
      : answers = List<int?>.filled(questions.length, null);

  final List<Question> questions;
  final List<int?> answers;
  final DateTime endsAt;
  int index = 0;
  bool over = false;
  bool timedOut = false;

  int get unanswered => answers.where((int? a) => a == null).length;
  int get score => scoreOf(questions, answers);
  bool get passed => isPassed(score);

  int secondsLeft(DateTime now) {
    final int ms = endsAt.difference(now).inMilliseconds;
    if (ms <= 0) return 0;
    return (ms + 999) ~/ 1000;
  }
}
