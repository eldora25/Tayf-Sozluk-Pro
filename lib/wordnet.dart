import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // Arka plan işlemi (compute) için
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

// UI'ı kitlemeden (RAM şişirmesini önleyerek) arka planda çalışacak Isolate fonksiyonu
Map<String, WordNetEntry> _decodeZipInBackground(List<int> zipBytes) {
  final archive = ZipDecoder().decodeBytes(zipBytes);
  
  ArchiveFile? jsonFile;
  // ZIP'in içinde klasör varsa diye adından bağımsız doğrudan ilk .json dosyasını arıyoruz
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
  String errorMessage = ""; // Hatayı uygulamanın ekranına taşımak için

  bool get isLoaded => _isLoaded;

  Future<void> loadWordNetData() async {
    if (_isLoaded) return;
    try {
      print("WordNet ZIP dosyası okunuyor...");
      final ByteData zipBytes = await rootBundle.load('assets/wordnet/wordnet_data.zip');
      
      print("Arka planda (Isolate) ZIP çıkarılıyor ve JSON ayrıştırılıyor...");
      // Devasa dosyayı çözerken UI'ı kitlememek ve RAM'i yormamak için compute kullanıyoruz
      _wordNetData = await compute(_decodeZipInBackground, zipBytes.buffer.asUint8List().toList());
      
      _isLoaded = true;
      errorMessage = "";
      print("WordNet verisi ZIP'ten başarıyla çıkarıldı: ${_wordNetData.length} kayıt.");
    } catch (e) {
      _isLoaded = false;
      errorMessage = e.toString();
      print("WordNet yüklenirken hata oluştu: $e");
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
