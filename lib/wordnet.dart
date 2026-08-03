import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:archive/archive.dart';
import 'models.dart';
import 'logger_screen.dart';

// Arka planda (Isolate) ZIP'i çözüp Isar'a uygun WordModel listesine dönüştüren fonksiyon
List<WordModel> _decodeZipToModels(List<int> zipBytes) {
  final archive = ZipDecoder().decodeBytes(zipBytes);
  
  ArchiveFile? jsonFile;
  for (var file in archive.files) {
    if (file.isFile && file.name.toLowerCase().endsWith('.json')) {
      jsonFile = file;
      break;
    }
  }

  if (jsonFile == null) {
    throw Exception("ZIP arşivi içinde geçerli bir .json dosyası bulunamadı.");
  }
  
  final String response = utf8.decode(jsonFile.content as List<int>);
  final Map<String, dynamic> data = json.decode(response);

  List<WordModel> extractedModels = [];

  data.forEach((key, value) {
    // UNKNOWN HATASI ÇÖZÜMÜ: Anahtarı (Key) kelimenin kendisi olarak alıyoruz
    String displayWord = key.trim();
    
    // Eğer key sadece bir sayı/ID ise (örn: 00001740-a) eşanlamlılara bak
    if (displayWord.isEmpty || RegExp(r'^\d{8}-').hasMatch(displayWord)) {
       List members = value['members'] ?? [];
       if (members.isNotEmpty) {
         displayWord = members.first.toString();
       } else {
         return; // Eşanlamlısı da yoksa anlamsızdır, pas geç
       }
    }

    List<String> defs = List<String>.from(value['definition'] ?? []);
    List<String> ex = List<String>.from(value['example'] ?? []);
    List<String> syns = List<String>.from(value['members'] ?? []);
    List<String> ants = List<String>.from(value['antonyms'] ?? []);
    String pos = value['partOfSpeech'] ?? value['pos'] ?? '';

    // Eşanlamlılar listesinden kendi adını çıkar (Gereksiz tekrarı önler)
    syns.removeWhere((s) => s.toLowerCase() == displayWord.toLowerCase());

    if (defs.isNotEmpty) {
      extractedModels.add(WordModel(
        word: displayWord,
        meanings: defs,
        examples: ex,
        synonyms: syns,
        antonyms: ants,
        pos: pos,
        libraryName: "WordNet Veritabanı",
        level: "WordNet",
        listType: "all",
      ));
    }
  });

  return extractedModels;
}

class WordNetInstaller {
  // Sadece ilk kurulumda bir kez çağrılır.
  static Future<List<WordModel>> getWordNetModels() async {
    try {
      GlobalLogger.addLog("WordNet Installer: ZIP dosyası okunuyor...");
      final ByteData zipBytes = await rootBundle.load('assets/wordnet/wordnet_data.zip');
      
      GlobalLogger.addLog("WordNet Installer: Arka plan (Isolate) ayrıştırması başlatıldı...");
      List<WordModel> models = await compute(_decodeZipToModels, zipBytes.buffer.asUint8List().toList());
      
      GlobalLogger.addLog("WordNet Installer BAŞARILI: ${models.length} kelime Isar'a gömülmek için hazırlandı.");
      return models;
    } catch (e) {
      GlobalLogger.addLog("WordNet Installer HATA: Yükleme başarısız. Detay: $e");
      return [];
    }
  }
}
