import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:archive/archive.dart';
import 'models.dart';
import 'logger_screen.dart'; // YENİ: Log servisi dahil edildi

class WordNetEntry {
  final String id;
  final List<String> definition;
  final List<String> example;
  final List<String> members; 
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

Map<String, WordNetEntry> _decodeZipInBackground(List<int> zipBytes) {
  final archive = ZipDecoder().decodeBytes(zipBytes);
  
  ArchiveFile? jsonFile;
  for (var file in archive.files) {
    if (file.isFile && file.name.toLowerCase().endsWith('.json')) {
      jsonFile = file;
      break;
    }
  }

  if (jsonFile == null) {
    throw Exception("ZIP arşivi içinde geçerli bir .json dosyası bulunamadı. Lütfen ZIP dosyasını kontrol edin.");
  }
  
  final String response = utf8.decode(jsonFile.content as List<int>);
  final Map<String, dynamic> data = json.decode(response);

  return data.map((key, value) => MapEntry(key, WordNetEntry.fromJson(key, value)));
}

class WordNetService {
  static final WordNetService _instance = WordNetService._internal();
  factory WordNetService() => _instance;
  WordNetService._internal();

  Map<String, WordNetEntry> _wordNetData = {};
  bool _isLoaded = false;
  String errorMessage = ""; 

  bool get isLoaded => _isLoaded;

  Future<void> loadWordNetData() async {
    if (_isLoaded) return;
    try {
      GlobalLogger.addLog("WordNet Service: ZIP dosyası asset/wordnet dizininden okunuyor...");
      final ByteData zipBytes = await rootBundle.load('assets/wordnet/wordnet_data.zip');
      
      GlobalLogger.addLog("WordNet Service: Isolate (Arka plan) aktarımı başlatıldı, ZIP çıkarılıyor...");
      _wordNetData = await compute(_decodeZipInBackground, zipBytes.buffer.asUint8List().toList());
      
      _isLoaded = true;
      errorMessage = "";
      GlobalLogger.addLog("WordNet Service BAŞARILI: ZIP'ten ${_wordNetData.length} kayıt RAM'e aktarıldı.");
    } catch (e) {
      _isLoaded = false;
      errorMessage = e.toString();
      GlobalLogger.addLog("WordNet Service HATA: Yükleme başarısız oldu. Detay: $e");
    }
  }

  List<WordModel> getRandomWords(int count) {
    if (!_isLoaded || _wordNetData.isEmpty) return [];
    var values = _wordNetData.values.toList()..shuffle();
    return values.take(count).map((e) => e.toWordModel()).toList();
  }

  List<WordNetEntry> searchWord(String word) {
    final searchKeyword = word.toLowerCase();
    return _wordNetData.values.where((entry) {
      return entry.members.any((m) => m.toLowerCase().contains(searchKeyword)) ||
             entry.definition.any((d) => d.toLowerCase().contains(searchKeyword));
    }).toList();
  }
}
