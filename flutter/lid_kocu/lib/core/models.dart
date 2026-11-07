// LiD Koçu — veri modeli: soru kataloğu, çeviriler, eyaletler.

/// Tek bir sınav sorusu (Almanca metin + 4 seçenek + doğru seçenek dizini).
class Question {
  const Question({
    required this.id,
    required this.de,
    required this.options,
    required this.correct,
    this.stateId,
    this.dated = false,
  });

  /// Genel sorularda "1".."300", eyalet sorularında "berlin-3" gibi.
  final String id;
  final String de;
  final List<String> options;
  final int correct;

  /// Eyalet sorusuysa eyalet kimliği; genel soruysa null.
  final String? stateId;

  /// Cevabı zamanla değişebilen soru ("güncel olabilir" uyarısı gösterilir).
  final bool dated;

  bool get isState => stateId != null;

  factory Question.fromJson(Map<String, dynamic> j, {String? stateId, bool dated = false}) {
    final List<String> o = (j['o'] as List<dynamic>).map((dynamic e) => e as String).toList(growable: false);
    return Question(
      id: j['id'] as String,
      de: j['de'] as String,
      options: o,
      correct: j['c'] as int,
      stateId: stateId,
      dated: dated,
    );
  }
}

class StateInfo {
  const StateInfo({required this.id, required this.name, required this.questions});
  final String id;
  final String name;
  final List<Question> questions;
}

class Catalog {
  Catalog({required this.stand, required this.general, required this.states})
      : _byId = <String, Question>{
          for (final Question q in general) q.id: q,
          for (final StateInfo s in states)
            for (final Question q in s.questions) q.id: q,
        };

  /// Katalog tarihi (ISO, ör. 2025-05-07).
  final String stand;
  final List<Question> general;
  final List<StateInfo> states;
  final Map<String, Question> _byId;

  int get totalQuestions => _byId.length;
  Question? byId(String id) => _byId[id];

  StateInfo stateById(String id) {
    for (final StateInfo s in states) {
      if (s.id == id) return s;
    }
    return states.first;
  }

  /// Çalışma havuzu: 300 genel + seçilen eyaletin 10 sorusu.
  List<Question> pool(String stateId) => <Question>[...general, ...stateById(stateId).questions];

  factory Catalog.fromJson(Map<String, dynamic> j) {
    final Set<String> dated = (j['dated'] as List<dynamic>).map((dynamic e) => e as String).toSet();
    final List<Question> general = (j['general'] as List<dynamic>)
        .map((dynamic e) {
          final Map<String, dynamic> m = e as Map<String, dynamic>;
          return Question.fromJson(m, dated: dated.contains(m['id'] as String));
        })
        .toList(growable: false);
    final List<StateInfo> states = (j['states'] as List<dynamic>).map((dynamic e) {
      final Map<String, dynamic> s = e as Map<String, dynamic>;
      final String sid = s['id'] as String;
      return StateInfo(
        id: sid,
        name: s['name'] as String,
        questions: (s['q'] as List<dynamic>)
            .map((dynamic qe) {
              final Map<String, dynamic> m = qe as Map<String, dynamic>;
              return Question.fromJson(m, stateId: sid, dated: dated.contains(m['id'] as String));
            })
            .toList(growable: false),
      );
    }).toList(growable: false);
    return Catalog(stand: j['stand'] as String, general: general, states: states);
  }
}

/// Bir sorunun bir dildeki çevirisi/açıklaması.
/// Almanca (de) kaydında yalnızca açıklama ([x]) ve görsel açıklamaları ([g]) bulunur.
class QuestionText {
  const QuestionText({this.q, this.o, this.x, this.g});

  /// Çevrilmiş soru metni (de için null).
  final String? q;

  /// Çevrilmiş 4 seçenek (de için null).
  final List<String>? o;

  /// Açıklama.
  final String? x;

  /// Resimli sorularda resmin metin açıklaması: 1 (soru resmi) ya da 4 (seçenek resimleri) öğe.
  final List<String>? g;

  static List<String>? _list(dynamic v) => v == null ? null : (v as List<dynamic>).map((dynamic e) => e as String).toList(growable: false);

  factory QuestionText.fromJson(Map<String, dynamic> j) => QuestionText(
        q: j['q'] as String?,
        o: _list(j['o']),
        x: j['x'] as String?,
        g: _list(j['g']),
      );
}

class Translations {
  const Translations(this._data);
  final Map<String, Map<String, QuestionText>> _data;

  int get length => _data.length;

  QuestionText? of(String questionId, String lang) => _data[questionId]?[lang];

  /// Almanca açıklama ve Almanca görsel açıklamaları.
  QuestionText? german(String questionId) => of(questionId, 'de');

  factory Translations.fromJson(Map<String, dynamic> j) {
    final Map<String, Map<String, QuestionText>> m = <String, Map<String, QuestionText>>{};
    j.forEach((String id, dynamic v) {
      final Map<String, dynamic> langs = v as Map<String, dynamic>;
      m[id] = <String, QuestionText>{
        for (final MapEntry<String, dynamic> e in langs.entries) e.key: QuestionText.fromJson(e.value as Map<String, dynamic>),
      };
    });
    return Translations(m);
  }
}
