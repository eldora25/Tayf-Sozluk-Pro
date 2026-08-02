import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class FirebaseSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Seçimli, Kütüphane Hedefli ve Akıllı Filtrelemeli Topluluğa Gönderim
  static Future<Map<String, dynamic>> syncCardsToCloud(List<WordModel> localWords, {required bool isMitosisPool, String? targetLibraryName}) async {
    final prefs = await SharedPreferences.getInstance();
    int currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    var targetCards = localWords;
    
    // Mitoz havuzu mu yoksa belirli bir standart kütüphane mi seçildi?
    if (isMitosisPool) {
      targetCards = targetCards.where((w) => w.libraryName.startsWith('🧬') || w.libraryName.startsWith('User_Recommended')).toList();
    } else if (targetLibraryName != null) {
      targetCards = targetCards.where((w) => w.libraryName == targetLibraryName).toList();
    }

    // 0 Kart Gönderim Engeli 1. Aşama
    if (targetCards.isEmpty) {
      return {"success": false, "message": "Gönderilebilecek uygun kart bulunamadı.", "count": 0};
    }

    // AĞ OPTİMİZASYONU: Sadece aktif olarak etkileşime girilmiş kartlar
    var cardsToSend = targetCards.where((w) => w.srsLevel > 0 || w.wrongCount > 0 || w.correctCount > 0).toList();

    // Sadece fallback (Yedek)
    if (cardsToSend.isEmpty) {
      cardsToSend = targetCards.take(50).toList(); 
    }

    // 0 Kart Gönderim Engeli 2. Aşama
    if (cardsToSend.isEmpty) {
      return {"success": false, "message": "Gönderilecek güncel veri bulunamadı.", "count": 0};
    }

    String collectionName = isMitosisPool ? 'global_mitosis_pool' : 'community_standard_pool';

    int syncedCount = 0;
    const int batchSize = 50;

    for (int i = 0; i < cardsToSend.length; i += batchSize) {
      var chunk = cardsToSend.skip(i).take(batchSize);
      WriteBatch batch = _firestore.batch();

      for (var word in chunk) {
        String safeWord = word.word.trim().toLowerCase();
        
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

    // Son senkronizasyon zaman damgasını güncelliyoruz
    await prefs.setInt('last_sync_time', currentTimestamp);
    
    return {
      "success": true,
      "count": syncedCount,
      "message": "Akıllı Senkronizasyon Başarılı!\n($syncedCount güncel kart aktarıldı)"
    };
  }

  // 2. Karantina ve Güven Skoru Düşürme
  static Future<void> reportCardErrorInCloud(WordModel word, {bool isMitosisPool = true}) async {
    try {
      String collectionName = isMitosisPool ? 'global_mitosis_pool' : 'community_standard_pool';
      String safeWord = word.word.trim().toLowerCase();
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
