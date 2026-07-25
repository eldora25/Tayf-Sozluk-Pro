import 'dart:convert';

// Akıllı Dil Algılama Algoritması
String detectLanguage(String text) {
  String lower = text.toLowerCase();
  // Türkçe'ye özgü karakterler varsa kesin Türkçedir
  if (RegExp(r'[çğıöşü]').hasMatch(lower)) return 'tr-TR';
  // İngilizce'ye özgü harfler varsa kesin İngilizcedir
  if (RegExp(r'[wqx]').hasMatch(lower)) return 'en-US';
  
  // Karakter yoksa yaygın kelimelerden tespit etmeye çalış
  final trWords = ['bir', 've', 'için', 'ile', 'de', 'da', 'mi', 'mu', 'bu', 'şu', 'o', 'ne', 'gibi', 'kadar', 'olarak', 'olan', 'göre', 'kabul', 'etmek', 'yapmak', 'olmak'];
  for (var w in trWords) {
    if (RegExp(r'\b' + w + r'\b').hasMatch(lower)) return 'tr-TR';
  }
  return 'en-US'; // Varsayılan
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
      'word': word,
      'meanings': meanings,
      'examples': examples,
      'level': level,
      'libraryName': libraryName,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
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
