import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
// Yeni eklediğimiz archive paketini içe aktarıyoruz
import 'package:archive/archive.dart';

class WordNetEntry {
  final List<String> definition;
  final List<String> example;
  final List<String> hypernym;
  final String ili;
  final List<String> members;
  final String partOfSpeech;
  final List<String> similar;

  WordNetEntry({
    required this.definition,
    required this.example,
    required this.hypernym,
    required this.ili,
    required this.members,
    required this.partOfSpeech,
    required this.similar,
  });

  factory WordNetEntry.fromJson(Map<String, dynamic> json) {
    return WordNetEntry(
      definition: List<String>.from(json['definition'] ?? []),
      example: List<String>.from(json['example'] ?? []),
      hypernym: List<String>.from(json['hypernym'] ?? []),
      ili: json['ili'] ?? '',
      members: List<String>.from(json['members'] ?? []),
      partOfSpeech: json['partOfSpeech'] ?? '',
      similar: List<String>.from(json['similar'] ?? []),
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
      // 1. ZIP dosyasını byte veri olarak oku
      final ByteData zipBytes = await rootBundle.load('assets/wordnet/wordnet_data.zip');
      
      // 2. ZIP'i bellekte çöz
      final archive = ZipDecoder().decodeBytes(zipBytes.buffer.asUint8List());
      
      // 3. İçindeki JSON dosyasını bul
      final jsonFile = archive.findFile('wordnet_data.json');
      if (jsonFile == null) {
        throw Exception("ZIP arşivi içinde wordnet_data.json bulunamadı.");
      }
      
      // 4. Byte verisini UTF-8 metne çevir ve JSON olarak ayrıştır
      final String response = utf8.decode(jsonFile.content as List<int>);
      final Map<String, dynamic> data = json.decode(response);

      _wordNetData = data.map((key, value) => MapEntry(key, WordNetEntry.fromJson(value)));
      _isLoaded = true;
      print("WordNet verisi ZIP'ten başarıyla çıkarıldı: ${_wordNetData.length} kayıt.");
    } catch (e) {
      print("WordNet yüklenirken hata oluştu: $e");
    }
  }

  WordNetEntry? getEntryById(String id) {
    return _wordNetData[id];
  }

  List<WordNetEntry> searchWord(String word) {
    return _wordNetData.values.where((entry) => entry.members.contains(word)).toList();
  }
}
