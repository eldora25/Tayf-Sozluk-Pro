import 'dart:convert';

// Akıllı Dil Algılama Algoritması
String detectLanguage(String text) {
  String lower = text.toLowerCase();
  if (RegExp(r'[çğıöşü]').hasMatch(lower)) return 'tr-TR';
  if (RegExp(r'[wqx]').hasMatch(lower)) return 'en-US';
  
  final trWords = ['bir', 've', 'için', 'ile', 'de', 'da', 'mi', 'mu', 'bu', 'şu', 'o', 'ne', 'gibi', 'kadar', 'olarak', 'olan', 'göre', 'kabul', 'etmek', 'yapmak', 'olmak'];
  for (var w in trWords) {
    if (RegExp(r'\b' + w + r'\b').hasMatch(lower)) return 'tr-TR';
  }
  return 'en-US';
}

// Kütüphane adına göre kesin dil tespiti
String getLanguageForWord(String text, String libraryName, {bool isMeaning = false}) {
  String lowerLib = libraryName.toLowerCase();
  bool isEnTr = lowerLib.contains('en-tr') || lowerLib.contains('ing-tr') || lowerLib.contains('ingilizce-türkçe') || lowerLib.contains('ingilizce');
  bool isTrEn = lowerLib.contains('tr-en') || lowerLib.contains('tr-ing') || lowerLib.contains('türkçe-ingilizce');

  if (isEnTr) {
    return isMeaning ? 'tr-TR' : 'en-US';
  } else if (isTrEn) {
    return isMeaning ? 'en-US' : 'tr-TR';
  }
  return detectLanguage(text);
}

class WordModel {
  String word;
  List<String> meanings;
  List<String> examples;
  String level;
  String libraryName;
  int correctCount;
  int wrongCount;

  WordModel({
    required this.word,
    required this.meanings,
    required this.examples,
    this.level = 'Genel',
    required this.libraryName,
    this.correctCount = 0,
    this.wrongCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'word': word, 'meanings': meanings, 'examples': examples,
      'level': level, 'libraryName': libraryName,
      'correctCount': correctCount, 'wrongCount': wrongCount,
    };
  }

  factory WordModel.fromMap(Map<String, dynamic> map) {
    return WordModel(
      word: map['word'] ?? '',
      meanings: List<String>.from(map['meanings'] ?? []),
      examples: List<String>.from(map['examples'] ?? []),
      level: map['level'] ?? 'Genel',
      libraryName: map['libraryName'] ?? 'Genel',
      correctCount: map['correctCount'] ?? 0,
      wrongCount: map['wrongCount'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());
  factory WordModel.fromJson(String source) => WordModel.fromMap(json.decode(source));
}
