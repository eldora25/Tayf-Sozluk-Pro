import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class FirebaseSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Topluluğa Gönder (Batch Upload & Composite Key Idempotency)
  static Future<int> syncMitosisCardsToCloud(List<WordModel> localWords) async {
    final prefs = await SharedPreferences.getInstance();
    int lastSync = prefs.getInt('last_sync_time') ?? 0;
    int currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Sadece yeni veya güncellenmiş mitoz/saf kartları filtrele
    var cardsToSend = localWords.where((w) {
      bool isMitosis = w.libraryName.startsWith('🧬') || w.libraryName.startsWith('User_Recommended');
      return isMitosis;
    }).toList();

    if (cardsToSend.isEmpty) return 0;

    // 50'li veya 100'lü paketler halinde (Batch) gönderim için bölme
    int syncedCount = 0;
    const int batchSize = 50;

    for (int i = 0; i < cardsToSend.length; i += batchSize) {
      var chunk = cardsToSend.skip(i).take(batchSize);
      WriteBatch batch = _firestore.batch();

      for (var word in chunk) {
        // Kompozit Anahtar (Composite Key): Kelime + İlk Anlam + Kütüphane eşsizliği
        String safeWord = word.word.trim().toLowerCase();
        String safeMeaning = word.meanings.isNotEmpty ? word.meanings.first.trim().toLowerCase() : "";
        String docId = base64Url.encode(utf8.encode("${safeWord}_${safeMeaning}_${word.libraryName}"));

        DocumentReference docRef = _firestore.collection('global_mitosis_pool').doc(docId);

        batch.set(docRef, {
          "dna_stamp": "DNA-${word.id.toString().padLeft(6, '0')}",
          "word": word.word,
          "meanings": word.meanings,
          "examples": word.examples,
          "level": word.level,
          "libraryName": word.libraryName,
          "trust_score": 100, // Başlangıç Güven Skoru
          "frequency": FieldValue.increment(1), // Popülarite skoru artışı
          "last_updated": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        syncedCount++;
      }

      await batch.commit();
    }

    // Zaman damgasını güncelle
    await prefs.setInt('last_sync_time', currentTimestamp);
    return syncedCount;
  }

  // 2. Buluttan Elit Havuz Verilerini Çekme (Quality Filter: Trust Score > 90)
  static Future<List<WordModel>> fetchElitePoolFromCloud({bool onlyMitosis = true}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('global_mitosis_pool')
          .where('trust_score', isGreaterThan: 90) // Kalite Filtresi
          .orderBy('trust_score', descending: true)
          .limit(500)
          .get();

      List<WordModel> downloadedWords = [];
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        downloadedWords.add(WordModel(
          word: data['word'] ?? '',
          meanings: List<String>.from(data['meanings'] ?? []),
          examples: List<String>.from(data['examples'] ?? []),
          level: data['level'] ?? 'Genel',
          libraryName: data['libraryName'] ?? 'Global Mitoz Havuzu',
          listType: 'all',
          srsLevel: 0,
        ));
      }
      return downloadedWords;
    } catch (e) {
      return [];
    }
  }

  // 3. Otonom İnfaz / Güven Skoru Düşürme (! Karantina Butonu için)
  static Future<void> reportCardErrorInCloud(WordModel word) async {
    try {
      String safeWord = word.word.trim().toLowerCase();
      String safeMeaning = word.meanings.isNotEmpty ? word.meanings.first.trim().toLowerCase() : "";
      String docId = base64Url.encode(utf8.encode("${safeWord}_${safeMeaning}_${word.libraryName}"));

      DocumentReference docRef = _firestore.collection('global_mitosis_pool').doc(docId);
      
      // Güven skorunu 15 puan düşür
      await docRef.update({
        "trust_score": FieldValue.increment(-15),
      });

      // Otonom İnfaz: Eğer skor sıfırın altına inerse buluttan otomatik silinir
      DocumentSnapshot snapshot = await docRef.get();
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        int currentScore = data['trust_score'] ?? 100;
        if (currentScore <= 0) {
          await docRef.delete();
        }
      }
    } catch (e) {}
  }
}
