import 'dart:convert';
import 'package:isar/isar.dart';

part 'models.g.dart';

@collection
class WordModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String word;

  List<String> meanings = [];
  List<String> examples = [];

  @Index()
  late String libraryName;

  @Index()
  late String level;

  @Index()
  int correctCount = 0;

  @Index()
  int wrongCount = 0;

  // 'all', 'learning', 'toRepeat', 'toSRSRepeat', 'learned'
  @Index()
  late String listType; 

  @Index()
  int srsLevel = 0;

  @Index()
  int nextReviewDate = 0;

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
  });

  factory WordModel.fromJson(String jsonStr) {
    Map<String, dynamic> map = json.decode(jsonStr);
    return WordModel(
      word: map['word'] ?? '',
      meanings: map['meanings'] != null ? List<String>.from(map['meanings']) : [],
      examples: map['examples'] != null ? List<String>.from(map['examples']) : [],
      libraryName: map['libraryName'] ?? 'Genel',
      level: map['level'] ?? 'Genel',
      correctCount: map['correctCount'] ?? 0,
      wrongCount: map['wrongCount'] ?? 0,
      listType: map['listType'] ?? 'all',
      srsLevel: map['srsLevel'] ?? 0,
      nextReviewDate: map['nextReviewDate'] ?? 0,
    );
  }
}
