import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class FirebaseSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Seçimli ve 50 Kart Sınırı Denetimli Topluluğa Gönderim
  static Future<Map<String, dynamic>> syncCardsToCloud(List<WordModel> localWords, {required bool isMitosisPool}) async {
    // Mitoz havuzu seçildiyse en az 50 saf kart olmalı
    var targetCards = localWords.where((w) {
      bool isMitosis = w.libraryName.startsWith('🧬') || w.libraryName.startsWith('User_Recommended');
      return isMitosis;
    }).toList();

    if (isMitosisPool && targetCards.length < 50) {
      return {
        "success": false,
        "message": "Global Mitoz Havuzuna katkıda bulunmak için en az 50 saf/mitoz kartınız olmalıdır! (Mevcut: ${targetCards.length})"
      };
    }

    if (targetCards.isEmpty) {
      return {
        "success": false,
        "message": "Gönderilebilecek uygun mitoz kart bulunamadı."
      };
    }

    final prefs = await SharedPreferences.getInstance();
    int currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String collectionName = isMitosisPool ? 'global_mitosis_pool' : 'community_standard_pool';

    int syncedCount = 0;
    const int batchSize = 50;

    for (int i = 0; i < targetCards.length; i += batchSize) {
      var chunk = targetCards.skip(i).take(batchSize);
      WriteBatch batch = _firestore.batch();

      for (var word in chunk) {
        String safeWord = word.word.trim().toLowerCase();
        String safeMeaning = word.meanings.isNotEmpty ? word.meanings.first.trim().toLowerCase() : "";
        
        // Güçlendirilmiş Kompozit Anahtar (Hash / Base64)
        String rawSignature = "${safeWord}_${word.meanings.join('|').toLowerCase()}_${word.libraryName}";
        String docId = base64Url.encode(utf8.encode(rawSignature));

        DocumentReference docRef = _firestore.collection(collectionName).doc(docId);

        batch.set(docRef, {
          "dna_stamp": "DNA-${word.id.toString().padLeft(6, '0')}",
          "word": word.word,
          "meanings": word.meanings,
          "examples": word.examples,
          "level": word.level,
          "libraryName": word.libraryName,
          "trust_score": 100,
          "frequency": FieldValue.increment(1),
          "last_updated": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        syncedCount++;
      }

      await batch.commit();
    }

    await prefs.setInt('last_sync_time', currentTimestamp);
    
    return {
      "success": true,
      "count": syncedCount,
      "message": "Başarıyla Topluluğa Katkıda Bulunuldu! ($syncedCount kart senkronize edildi) +50 TP 🎉"
    };
  }

  // 2. Karantina ve Güven Skoru Düşürme
  static Future<void> reportCardErrorInCloud(WordModel word, {bool isMitosisPool = true}) async {
    try {
      String collectionName = isMitosisPool ? 'global_mitosis_pool' : 'community_standard_pool';
      String safeWord = word.word.trim().toLowerCase();
      String safeMeaning = word.meanings.isNotEmpty ? word.meanings.first.trim().toLowerCase() : "";
      String rawSignature = "${safeWord}_${word.meanings.join('|').toLowerCase()}_${word.libraryName}";
      String docId = base64Url.encode(utf8.encode(rawSignature));

      DocumentReference docRef = _firestore.collection(collectionName).doc(docId);
      
      await docRef.update({
        "trust_score": FieldValue.increment(-15),
      });

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
