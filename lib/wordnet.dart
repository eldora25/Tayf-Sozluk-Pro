import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:archive/archive.dart';
import 'models.dart';

class WordNetEntry {
  final String id;
  final List<String> definition;
  final List<String> example;
  final List<String> members; // Synonyms
  final List<String> antonyms;
  final String partOfSpeech;

  WordNetEntry({
    required this.id,
    required this.definition,
    required this.example,
    required this.members,
    required this.antonyms,
    required this.partOfSpeech,
  });

  factory WordNetEntry.fromJson(String id, Map<String, dynamic> json) {
    return WordNetEntry(
      id: id,
      definition: List<String>.from(json['definition'] ?? []),
      example: List<String>.from(json['example'] ?? []),
      members: List<String>.from(json['members'] ?? []),
      antonyms: List<String>.from(json['antonyms'] ?? []),
      partOfSpeech: json['partOfSpeech'] ?? json['pos'] ?? '',
    );
  }

  // ZIP'ten gelen ham veriyi uygulamanın anlayacağı WordModel'e çeviren köprü
  WordModel toWordModel() {
    return WordModel(
      word: members.isNotEmpty ? members.first : "Unknown",
      meanings: definition,
      examples: example,
      synonyms: members.length > 1 ? members.sublist(1) : [],
      antonyms: antonyms,
      pos: partOfSpeech,
      libraryName: "WordNet Veritabanı",
      level: "WordNet",
      listType: "all",
    );
  }
}

class WordNetService {
  static final WordNetService _instance = WordNetService._internal();
  factory WordNetService() => _instance;
  WordNetService._internal();

  Map<String, WordNetEntry> _wordNetData = {};
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Future<void> loadWordNetData() async {
    if (_isLoaded) return;
    try {
      print("WordNet ZIP dosyası okunuyor...");
      final ByteData zipBytes = await rootBundle.load('assets/wordnet/wordnet_data.zip');
      final archive = ZipDecoder().decodeBytes(zipBytes.buffer.asUint8List());
      final jsonFile = archive.findFile('wordnet_data.json');
      if (jsonFile == null) throw Exception("ZIP arşivi içinde wordnet_data.json bulunamadı.");
      
      print("JSON verisi ayrıştırılıyor...");
      final String response = utf8.decode(jsonFile.content as List<int>);
      final Map<String, dynamic> data = json.decode(response);

      _wordNetData = data.map((key, value) => MapEntry(key, WordNetEntry.fromJson(key, value)));
      _isLoaded = true;
      print("WordNet verisi ZIP'ten başarıyla çıkarıldı: ${_wordNetData.length} kayıt.");
    } catch (e) {
      print("WordNet yüklenirken hata oluştu: $e");
    }
  }

  // Quiz ve Oyunlar için cihazı yormadan anlık kelime havuzu oluşturur
  List<WordModel> getRandomWords(int count) {
    if (!_isLoaded || _wordNetData.isEmpty) return [];
    var values = _wordNetData.values.toList()..shuffle();
    return values.take(count).map((e) => e.toWordModel()).toList();
  }

  // WordNet Browser için arama motoru
  List<WordNetEntry> searchWord(String word) {
    final searchKeyword = word.toLowerCase();
    return _wordNetData.values.where((entry) {
      return entry.members.any((m) => m.toLowerCase().contains(searchKeyword)) ||
             entry.definition.any((d) => d.toLowerCase().contains(searchKeyword));
    }).toList();
  }
}
