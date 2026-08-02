import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class FirebaseSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Seçimli ve Akıllı Filtrelemeli (Son Senkronizasyon Zaman Damgası) Topluluğa Gönderim
  static Future<Map<String, dynamic>> syncCardsToCloud(List<WordModel> localWords, {required bool isMitosisPool}) async {
    final prefs = await SharedPreferences.getInstance();
    int lastSyncTime = prefs.getInt('last_sync_time') ?? 0;
    int currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Mitoz havuzu seçildiyse uygun kartları filtrele
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

    // AĞ OPTİMİZASYONU: Sadece aktif olarak etkileşime girilmiş veya son sync'ten sonra dokunulmuş kartlar
    // Veya ilk kez senkronize edilen akıllı havuz kartları filtrelenir.
    var cardsToSend = targetCards.where((w) {
      // Eğer kartın SRS seviyesi, yanlış/doğru sayısı değişmişse veya hiç senkronize edilmediyse gönder
      return w.srsLevel > 0 || w.wrongCount > 0 || w.correctCount > 0;
    }).toList();

    // Eğer filtrelenen özel kart yoksa ama kullanıcı zorla göndermek istiyorsa targetCards fallback kullanılabilir
    // Ancak ağ tasarrufu için akıllı küme esastır. Havuz boş kalmasın diye hedef kart kalmadıysa targetCards[0]'ı baz alabiliriz.
    if (cardsToSend.isEmpty) {
      cardsToSend = targetCards.take(50).toList(); 
    }

    String collectionName = isMitosisPool ? 'global_mitosis_pool' : 'community_standard_pool';

    int syncedCount = 0;
    const int batchSize = 50;

    for (int i = 0; i < cardsToSend.length; i += batchSize) {
      var chunk = cardsToSend.skip(i).take(batchSize);
      WriteBatch batch = _firestore.batch();

      for (var word in chunk) {
        String safeWord = word.word.trim().toLowerCase();
        
        // Güçlendirilmiş Kompozit Anahtar (Hash / Base64)[cite: 2]
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
      "message": "Akıllı Senkronizasyon Başarılı! ($syncedCount güncel kart aktarıldı) +50 TP 🎉"
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
