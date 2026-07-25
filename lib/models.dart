import 'dart:convert';

// Akıllı ve Performanslı Dil Algılama
String getSourceLanguage(String libraryName) {
  String lowerLib = libraryName.toLowerCase();
  // Öncelik kütüphane ismindedir
  if (lowerLib.contains('tr-en') || lowerLib.contains('tr-ing') || lowerLib.contains('türkçe-ing')) return 'tr-TR';
  if (lowerLib.contains('en-tr') || lowerLib.contains('ing-tr') || lowerLib.contains('ingilizce')) return 'en-US';
  return 'en-US'; // Varsayılan
}

String getTargetLanguage(String libraryName) {
  String lowerLib = libraryName.toLowerCase();
  if (lowerLib.contains('tr-en') || lowerLib.contains('tr-ing') || lowerLib.contains('türkçe-ing')) return 'en-US';
  if (lowerLib.contains('en-tr') || lowerLib.contains('ing-tr') || lowerLib.contains('ingilizce')) return 'tr-TR';
  return 'tr-TR'; // Varsayılan
}

// Güvenlik amaçlı tekil kelime tespiti (Eğer kütüphanede belirtilmemişse)
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
