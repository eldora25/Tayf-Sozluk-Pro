import 'dart:convert';
import 'package:isar/isar.dart';

// Veritabanı tabloları otomatik bu dosyada oluşacak
part 'models.g.dart';

// Akıllı ve Performanslı Dil Algılama
String getSourceLanguage(String libraryName) {
  String lowerLib = libraryName.toLowerCase();
  if (lowerLib.contains('tr-en') || lowerLib.contains('tr-ing') || lowerLib.contains('türkçe-ing')) return 'tr-TR';
  if (lowerLib.contains('en-tr') || lowerLib.contains('ing-tr') || lowerLib.contains('ingilizce')) return 'en-US';
  return 'en-US';
}

String getTargetLanguage(String libraryName) {
  String lowerLib = libraryName.toLowerCase();
  if (lowerLib.contains('tr-en') || lowerLib.contains('tr-ing') || lowerLib.contains('türkçe-ing')) return 'en-US';
  if (lowerLib.contains('en-tr') || lowerLib.contains('ing-tr') || lowerLib.contains('ingilizce')) return 'tr-TR';
  return 'tr-TR'; 
}

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

@collection
class WordModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  String word;

  List<String> meanings;
  List<String> examples;
  String level;

  @Index(type: IndexType.value)
  String libraryName;

  int correctCount;
  int wrongCount;

  // Hangi listede olduğunu (all, learned, toRepeat, wrong) belirler
  @Index(type: IndexType.value)
  String listType; 

  WordModel({
    this.word = '',
    this.meanings = const [],
    this.examples = const [],
    this.level = 'Genel',
    this.libraryName = 'Genel',
    this.correctCount = 0,
    this.wrongCount = 0,
    this.listType = 'all',
  });

  Map<String, dynamic> toMap() {
    return {
      'word': word, 'meanings': meanings, 'examples': examples,
      'level': level, 'libraryName': libraryName,
      'correctCount': correctCount, 'wrongCount': wrongCount,
      'listType': listType,
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
      listType: map['listType'] ?? 'all',
    );
  }

  String toJson() => json.encode(toMap());
  factory WordModel.fromJson(String source) => WordModel.fromMap(json.decode(source));
}
