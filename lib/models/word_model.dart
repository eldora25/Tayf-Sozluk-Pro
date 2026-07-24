import 'dart:convert';

class WordModel {
  final String word;
  final List<String> meanings;
  final List<String> examples;
  final String level;
  final String libraryName;
  int quizCorrectCount;

  WordModel({
    required this.word,
    required this.meanings,
    required this.examples,
    required this.level,
    required this.libraryName,
    this.quizCorrectCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'meanings': meanings,
      'examples': examples,
      'level': level,
      'libraryName': libraryName,
      'quizCorrectCount': quizCorrectCount,
    };
  }

  factory WordModel.fromMap(Map<String, dynamic> map) {
    return WordModel(
      word: map['word'] ?? '',
      meanings: List<String>.from(map['meanings'] ?? []),
      examples: List<String>.from(map['examples'] ?? []),
      level: map['level'] ?? 'Genel',
      libraryName: map['libraryName'] ?? 'Genel',
      quizCorrectCount: map['quizCorrectCount'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());
  factory WordModel.fromJson(String source) => WordModel.fromMap(json.decode(source));
}

class WrongWordModel {
  final WordModel wordInfo;
  int wrongCount;

  WrongWordModel({required this.wordInfo, this.wrongCount = 1});

  Map<String, dynamic> toMap() {
    return {
      'wordInfo': wordInfo.toMap(),
      'wrongCount': wrongCount,
    };
  }

  factory WrongWordModel.fromMap(Map<String, dynamic> map) {
    return WrongWordModel(
      wordInfo: WordModel.fromMap(map['wordInfo']),
      wrongCount: map['wrongCount'] ?? 1,
    );
  }
}
