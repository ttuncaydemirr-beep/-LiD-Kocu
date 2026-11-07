import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lid_kocu/core/exam.dart';
import 'package:lid_kocu/core/models.dart';
import 'package:lid_kocu/data/app_data.dart';

import 'helpers.dart';

void main() {
  late AppData data;
  setUpAll(() async {
    data = await loadData();
  });

  test('kurallar: 33 soru (30+3), 60 dakika, 17 doğru', () {
    expect(ExamRules.total, 33);
    expect(ExamRules.generalCount, 30);
    expect(ExamRules.stateCount, 3);
    expect(ExamRules.minutes, 60);
    expect(ExamRules.passMark, 17);
    expect(ExamRules.freeExams, 2);
  });

  test('sınav seçimi: 30 genel + seçilen eyaletten 3 soru, tekrarsız', () {
    for (int seed = 0; seed < 100; seed++) {
      final StateInfo st = data.catalog.states[seed % data.catalog.states.length];
      final List<Question> exam = pickExam(data.catalog.general, st.questions, Random(seed));
      expect(exam.length, 33);
      expect(exam.map((Question q) => q.id).toSet().length, 33, reason: 'tekrar var (seed $seed)');
      final List<Question> general = exam.where((Question q) => !q.isState).toList();
      final List<Question> state = exam.where((Question q) => q.isState).toList();
      expect(general.length, 30);
      expect(state.length, 3);
      expect(state.every((Question q) => q.stateId == st.id), isTrue);
    }
  });

  test('sınav seçimi: farklı tohumlar farklı sorular ve sıra verir; kaynak listeler değişmez', () {
    final List<Question> before = List<Question>.of(data.catalog.general);
    final List<String> a = pickExam(data.catalog.general, data.catalog.stateById('berlin').questions, Random(1)).map((Question q) => q.id).toList();
    final List<String> b = pickExam(data.catalog.general, data.catalog.stateById('berlin').questions, Random(2)).map((Question q) => q.id).toList();
    expect(a, isNot(equals(b)));
    expect(data.catalog.general, equals(before));
  });

  test('yetersiz soru havuzunda hata verir', () {
    expect(() => pickExam(data.catalog.general.take(10).toList(), data.catalog.stateById('berlin').questions, Random(1)), throwsArgumentError);
    expect(() => pickExam(data.catalog.general, data.catalog.stateById('berlin').questions.take(2).toList(), Random(1)), throwsArgumentError);
  });

  List<int?> answersWithCorrect(List<Question> qs, int correct) => <int?>[
        for (int i = 0; i < qs.length; i++) i < correct ? qs[i].correct : (qs[i].correct + 1) % 4,
      ];

  test('puanlama: 16 doğru kalır, 17 doğru geçer', () {
    final List<Question> qs = pickExam(data.catalog.general, data.catalog.stateById('bayern').questions, Random(7));
    expect(scoreOf(qs, answersWithCorrect(qs, 16)), 16);
    expect(isPassed(scoreOf(qs, answersWithCorrect(qs, 16))), isFalse);
    expect(scoreOf(qs, answersWithCorrect(qs, 17)), 17);
    expect(isPassed(scoreOf(qs, answersWithCorrect(qs, 17))), isTrue);
    expect(isPassed(scoreOf(qs, answersWithCorrect(qs, 33))), isTrue);
    expect(isPassed(scoreOf(qs, answersWithCorrect(qs, 0))), isFalse);
  });

  test('boş bırakılan soru yanlış sayılır', () {
    final List<Question> qs = pickExam(data.catalog.general, data.catalog.stateById('bayern').questions, Random(7));
    final List<int?> answers = answersWithCorrect(qs, 33);
    answers[0] = null;
    answers[5] = null;
    expect(scoreOf(qs, answers), 31);
    final ExamSession s = ExamSession(questions: qs, endsAt: DateTime(2030));
    expect(s.unanswered, 33);
    s.answers.setAll(0, answers);
    expect(s.unanswered, 2);
    expect(s.score, 31);
    expect(s.passed, isTrue);
  });

  test('ücretsiz deneme sınırı: 2 hak, premium sınırsız', () {
    expect(mayStartExam(premium: false, examsUsed: 0), isTrue);
    expect(mayStartExam(premium: false, examsUsed: 1), isTrue);
    expect(mayStartExam(premium: false, examsUsed: 2), isFalse);
    expect(mayStartExam(premium: false, examsUsed: 5), isFalse);
    expect(mayStartExam(premium: true, examsUsed: 99), isTrue);
    expect(freeExamsLeft(premium: false, examsUsed: 0), 2);
    expect(freeExamsLeft(premium: false, examsUsed: 1), 1);
    expect(freeExamsLeft(premium: false, examsUsed: 2), 0);
    expect(freeExamsLeft(premium: false, examsUsed: 7), 0);
    expect(freeExamsLeft(premium: true, examsUsed: 0), isNull);
  });

  test('kalan süre: yukarı yuvarlanır, bitince 0', () {
    final DateTime start = DateTime(2030, 1, 1, 10);
    final ExamSession s = ExamSession(
      questions: pickExam(data.catalog.general, data.catalog.stateById('berlin').questions, Random(3)),
      endsAt: start.add(const Duration(minutes: ExamRules.minutes)),
    );
    expect(s.secondsLeft(start), 3600);
    expect(s.secondsLeft(start.add(const Duration(milliseconds: 1))), 3600);
    expect(s.secondsLeft(start.add(const Duration(seconds: 1))), 3599);
    expect(s.secondsLeft(start.add(const Duration(minutes: 60))), 0);
    expect(s.secondsLeft(start.add(const Duration(minutes: 61))), 0);
  });
}
