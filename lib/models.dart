import 'dart:convert';
import 'package:isar/isar.dart';

part 'models.g.dart';

@collection
class WordModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.hash)
  late String word;

  late List<String> meanings;
  late List<String> examples;
  
  @Index(type: IndexType.hash)
  late String libraryName;
  
  @Index(type: IndexType.hash)
  late String level;

  @Index(type: IndexType.value)
  int correctCount = 0;
  
  @Index(type: IndexType.value)
  int wrongCount = 0;

  @Index(type: IndexType.hash)
  String listType = 'all';

  @Index(type: IndexType.value)
  int srsLevel = 0;
  
  @Index(type: IndexType.value)
  int nextReviewDate = 0;

  String sourceLanguage = 'en-US';
  String targetLanguage = 'tr-TR';

  String pos = '';
  List<String> synonyms = [];
  List<String> antonyms = [];

  // YENİ: Mitoz klonlarının atasını takip eden genetik miras parametresi
  String? rootWord; 

  WordModel({
    required this.word,
    required this.meanings,
    required this.examples,
    required this.libraryName,
    required this.level,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.listType = 'all',
    this.srsLevel = 0,
    this.nextReviewDate = 0,
    this.sourceLanguage = 'en-US',
    this.targetLanguage = 'tr-TR',
    this.pos = '',
    this.synonyms = const [],
    this.antonyms = const [],
    this.rootWord,
  });

  factory WordModel.fromJson(String jsonString) {
    Map<String, dynamic> map = json.decode(jsonString);
    return WordModel(
      word: map['word'] ?? '',
      meanings: List<String>.from(map['meanings'] ?? []),
      examples: List<String>.from(map['examples'] ?? []),
      libraryName: map['libraryName'] ?? 'Varsayılan',
      level: map['level'] ?? 'Genel',
      correctCount: map['correctCount'] ?? 0,
      wrongCount: map['wrongCount'] ?? 0,
      listType: map['listType'] ?? 'all',
      srsLevel: map['srsLevel'] ?? 0,
      nextReviewDate: map['nextReviewDate'] ?? 0,
      sourceLanguage: map['sourceLanguage'] ?? 'en-US',
      targetLanguage: map['targetLanguage'] ?? 'tr-TR',
      pos: map['pos'] ?? '',
      synonyms: map['synonyms'] != null ? List<String>.from(map['synonyms']) : [],
      antonyms: map['antonyms'] != null ? List<String>.from(map['antonyms']) : [],
      rootWord: map['rootWord'],
    );
  }
}

class WrongWordModel {
  final WordModel wordInfo;
  final int wrongCount;
  WrongWordModel({required this.wordInfo, required this.wrongCount});
}
