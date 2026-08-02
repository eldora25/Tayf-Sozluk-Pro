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

  // TTS için Kalıcı Dil Kimliği Parametreleri
  String sourceLanguage = 'en-US';
  String targetLanguage = 'tr-TR';

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
    );
  }
}
```[cite: 12]

Lütfen yerel projenizdeki `models.dart` dosyasının tamamını silip bu kod bloğunu yapıştırın ve GitHub'a kaydedip gönderin. Bu sayede `build_runner` hatasız bir şekilde tamamlanacaktır.
