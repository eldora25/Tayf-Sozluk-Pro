import 'dart:async';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'models.dart';
import 'main.dart'; 
import 'notification_service.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {

  void _triggerRealNotification() {
    NotificationService.showInstantTestNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Gerçek sistem bildirimi tetiklendi!"), backgroundColor: Colors.green)
    );
  }

  // ÇÖZÜM: Kelimeler artık 'Demo Sözlük' yerine 'Varsayılan' kütüphanesine ekleniyor, 
  // böylece Ana Ekranda (Varsayılan seçiliyken) anında karşınıza çıkacak.
  Future<void> _injectFiveLevelDemoWords() async {
    int pastTime = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    
    List<WordModel> demoWords = [
      WordModel(word: 'Level 1 Word', meanings: ['Seviye 1 Gümüş/Mavi Çerçeve'], examples: [], libraryName: 'Varsayılan', listType: 'toSRSRepeat', level: 'Genel')..srsLevel = 1..nextReviewDate = pastTime,
      WordModel(word: 'Level 2 Word', meanings: ['Seviye 2 Yeşil Çerçeve'], examples: [], libraryName: 'Varsayılan', listType: 'toSRSRepeat', level: 'Genel')..srsLevel = 2..nextReviewDate = pastTime,
      WordModel(word: 'Level 3 Word', meanings: ['Seviye 3 Sarı Çerçeve'], examples: [], libraryName: 'Varsayılan', listType: 'toSRSRepeat', level: 'Genel')..srsLevel = 3..nextReviewDate = pastTime,
      WordModel(word: 'Level 4 Word', meanings: ['Seviye 4 Turuncu Çerçeve'], examples: [], libraryName: 'Varsayılan', listType: 'toSRSRepeat', level: 'Genel')..srsLevel = 4..nextReviewDate = pastTime,
      WordModel(word: 'Level 5 Word', meanings: ['Seviye 5 Kırmızı Çerçeve'], examples: [], libraryName: 'Varsayılan', listType: 'toSRSRepeat', level: 'Genel')..srsLevel = 5..nextReviewDate = pastTime,
    ];

    await isar.writeTxn(() async {
      await isar.wordModels.putAll(demoWords);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("5 farklı demo kelime 'Varsayılan' kütüphanesine eklendi! Ana ekranda görebilirsiniz."), backgroundColor: Colors.green)
      );
    }
  }

  Future<void> _timeTravelForward() async {
    List<WordModel> learningWords = await isar.wordModels.filter().listTypeEqualTo('learning').findAll();
    if (learningWords.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Havuzda zamanı ileri sarılacak kelime yok!\n(Önce ana ekranda yeni kelimeleri 'Biliyorum' diyerek eğitime alın)"), 
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        )
      );
      return;
    }

    int twoDaysMs = 2 * 24 * 60 * 60 * 1000;
    for (var w in learningWords) {
      w.nextReviewDate = w.nextReviewDate - twoDaysMs;
      // Zamanı dolanlar otomatik toSRSRepeat'e düşüyor
      if (w.nextReviewDate <= DateTime.now().millisecondsSinceEpoch) w.listType = 'toSRSRepeat';
    }

    await isar.writeTxn(() async { await isar.wordModels.putAll(learningWords); });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Zaman 2 gün ileri sarıldı! Eğitimdeki kelimeleriniz SRS Tekrar Listesine düştü."), backgroundColor: Colors.blueAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sistem & SRS Demo", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // HAVALI AÇIKLAMA GERİ DÖNDÜ!
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.purple.shade700, Colors.deepPurpleAccent.shade400]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))]
            ),
            child: Column(
              children: const [
                Icon(Icons.science, size: 50, color: Colors.white),
                SizedBox(height: 12),
                Text("Geliştirici Test Laboratuvarı", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 8),
                Text("Bu alan, arka planda çalışan SRS algoritmalarını, bildirimleri ve premium UI bileşenlerini saniyeler içinde simüle edebilmeniz için tasarlanmıştır.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Card(
            elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.phonelink_ring, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 10),
                  const Text("Gerçek Cihaz Bildirimi Testi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Bu butona basıldığında Android/iOS sistemine 'gerçek' bir bildirim sinyali gönderilir.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                    icon: const Icon(Icons.notifications_active),
                    label: const Text("Gerçek Bildirim Gönder"),
                    onPressed: _triggerRealNotification,
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.filter_frames, size: 48, color: Colors.green),
                  const SizedBox(height: 10),
                  const Text("5 Seviye Çerçeve Testi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Ana ekrandaki Premium Animasyonlu Çerçeveleri görmek için Varsayılan listesine 1'den 5'e kadar seviyelendirilmiş kelimeler ekler.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), 
                    icon: const Icon(Icons.add), 
                    label: const Text("5 Seviye Çerçeve Demosu Yükle"), 
                    onPressed: _injectFiveLevelDemoWords
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.history_toggle_off, size: 48, color: Colors.blueAccent),
                  const SizedBox(height: 10),
                  const Text("Zaman Makinesi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("SRS havuzunda uslu uslu bekleyen kelimelerinizin sürelerini anında doldurup 'Tekrar' listesine düşürür.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white), icon: const Icon(Icons.fast_forward), label: const Text("Zamanı 2 Gün İleri Sar"), onPressed: _timeTravelForward)
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
