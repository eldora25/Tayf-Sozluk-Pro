import 'dart:async';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:isar/isar.dart';
import 'models.dart';
import 'core/db_helper.dart';
import 'core/tts_manager.dart';
import 'notification_service.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {

  void _triggerRealNotification() {
    HapticFeedback.heavyImpact(); 
    NotificationService.showInstantTestNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Gerçek sistem bildirimi tetiklendi!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating)
    );
  }

  Future<void> _injectFiveLevelDemoWords() async {
    HapticFeedback.mediumImpact();
    int pastTime = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    
    await isar.writeTxn(() async {
      await isar.wordModels.filter().wordStartsWith('Level ').deleteAll();
      await isar.wordModels.filter().wordStartsWith('Mitoz L').deleteAll();
    });
    
    List<WordModel> demoWords = [
      WordModel(word: 'Level 1 Normal', meanings: ['Normal L1 Sarı Çerçeve'], examples: ['Bu standart çok anlamlı bir kart.'], libraryName: 'Varsayılan', level: 'Genel', listType: 'toSRSRepeat', srsLevel: 1, nextReviewDate: pastTime, correctCount: 1),
      WordModel(word: 'Level 2 Normal', meanings: ['Normal L2 Mor Çerçeve'], examples: ['Bu standart çok anlamlı bir kart.'], libraryName: 'Varsayılan', level: 'Genel', listType: 'toSRSRepeat', srsLevel: 2, nextReviewDate: pastTime, correctCount: 2),
      WordModel(word: 'Level 3 Normal', meanings: ['Normal L3 Mavi Çerçeve'], examples: ['Bu standart çok anlamlı bir kart.'], libraryName: 'Varsayılan', level: 'Genel', listType: 'toSRSRepeat', srsLevel: 3, nextReviewDate: pastTime, correctCount: 3),
      WordModel(word: 'Level 4 Normal', meanings: ['Normal L4 Turuncu Çerçeve'], examples: ['Bu standart çok anlamlı bir kart.'], libraryName: 'Varsayılan', level: 'Genel', listType: 'toSRSRepeat', srsLevel: 4, nextReviewDate: pastTime, correctCount: 4),
      WordModel(word: 'Level 5 Normal', meanings: ['Normal L5 Yeşil Çerçeve'], examples: ['Bu standart çok anlamlı bir kart.'], libraryName: 'Varsayılan', level: 'Genel', listType: 'toSRSRepeat', srsLevel: 5, nextReviewDate: pastTime, correctCount: 5),

      WordModel(word: 'Mitoz L1 Saf', meanings: ['Mitoz L1 Sarı Çerçeve'], examples: ['Bu bölünmüş saf (atomic) bir kart.'], libraryName: '🧬 Mitoz (Demo)', level: 'Genel', listType: 'toSRSRepeat', srsLevel: 1, nextReviewDate: pastTime, correctCount: 1),
      WordModel(word: 'Mitoz L2 Saf', meanings: ['Mitoz L2 Mor Çerçeve'], examples: ['Bu bölünmüş saf (atomic) bir kart.'], libraryName: '🧬 Mitoz (Demo)', level: 'Genel', listType: 'toSRSRepeat', srsLevel: 2, nextReviewDate: pastTime, correctCount: 2),
      WordModel(word: 'Mitoz L3 Saf', meanings: ['Mitoz L3 Mavi Çerçeve'], examples: ['Bu bölünmüş saf (atomic) bir kart.'], libraryName: '🧬 Mitoz (Demo)', level: 'Genel', listType: 'toSRSRepeat', srsLevel: 3, nextReviewDate: pastTime, correctCount: 3),
      WordModel(word: 'Mitoz L4 Saf', meanings: ['Mitoz L4 Turuncu Çerçeve'], examples: ['Bu bölünmüş saf (atomic) bir kart.'], libraryName: '🧬 Mitoz (Demo)', level: 'Genel', listType: 'toSRSRepeat', srsLevel: 4, nextReviewDate: pastTime, correctCount: 4),
      WordModel(word: 'Mitoz L5 Saf', meanings: ['Mitoz L5 Yeşil Çerçeve'], examples: ['Bu bölünmüş saf (atomic) bir kart.'], libraryName: '🧬 Mitoz (Demo)', level: 'Genel', listType: 'toSRSRepeat', srsLevel: 5, nextReviewDate: pastTime, correctCount: 5),
    ];

    await isar.writeTxn(() async {
      await isar.wordModels.putAll(demoWords);
    });

    if (mounted) {
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✨ Süper Demo Yüklendi! 5 Normal + 5 Mitoz SRS Çerçevesi karşınızda."), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating)
      );
    }
  }

  Future<void> _timeTravelForward() async {
    HapticFeedback.mediumImpact();
    List<WordModel> learningWords = await isar.wordModels.filter().listTypeEqualTo('learning').findAll();
    if (learningWords.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Havuzda zamanı ileri sarılacak kelime yok!\n(Önce ana ekranda yeni kelimeleri 'Biliyorum' diyerek eğitime alın)"), 
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating
        )
      );
      return;
    }

    for (var w in learningWords) {
      w.nextReviewDate = DateTime.now().millisecondsSinceEpoch - 1000;
      w.listType = 'toSRSRepeat';
    }

    await isar.writeTxn(() async { await isar.wordModels.putAll(learningWords); });
    
    if (mounted) {
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Zaman Makinesi Çalıştı! Eğitimdeki TÜM kelimeleriniz anında SRS Tekrar Listesine düştü."), backgroundColor: Colors.blueAccent, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sistem & SRS Demo", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 40.0),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.purple.shade700, Colors.deepPurpleAccent.shade400], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]
            ),
            child: Column(
              children: const [
                Icon(Icons.science, size: 54, color: Colors.white),
                SizedBox(height: 12),
                Text("Geliştirici Test Laboratuvarı", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
                SizedBox(height: 8),
                Text("Bu alan, arka planda çalışan SRS algoritmalarını, bildirimleri ve premium UI bileşenlerini saniyeler içinde simüle edebilmeniz için tasarlanmıştır.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildDemoCard(
            title: "Gerçek Cihaz Bildirimi Testi",
            description: "Bu butona basıldığında Android/iOS sistemine 'gerçek' bir bildirim sinyali gönderilir.",
            icon: Icons.phonelink_ring,
            color: Colors.redAccent,
            buttonText: "Gerçek Bildirim Gönder",
            buttonIcon: Icons.notifications_active,
            onPressed: _triggerRealNotification,
          ),

          _buildDemoCard(
            title: "10 Seviye Çerçeve Testi (5 Normal + 5 Mitoz)",
            description: "Ana ekrandaki Premium Animasyonlu Çerçevelerin hem standart kelimeler hem de saf 'Mitoz' kartları üzerinde nasıl durduğunu gösterir.",
            icon: Icons.filter_frames,
            color: Colors.green,
            buttonText: "Süper Çerçeve Demosu Yükle",
            buttonIcon: Icons.add,
            onPressed: _injectFiveLevelDemoWords,
          ),

          _buildDemoCard(
            title: "Zaman Makinesi",
            description: "SRS havuzunda uslu uslu bekleyen kelimelerinizin sürelerini anında doldurup 'Tekrar' listesine düşürür.",
            icon: Icons.history_toggle_off,
            color: Colors.blueAccent,
            buttonText: "Zamanı İleri Sar (Tümünü Getir)",
            buttonIcon: Icons.fast_forward,
            onPressed: _timeTravelForward,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildDemoCard({required String title, required String description, required IconData icon, required Color color, required String buttonText, required IconData buttonIcon, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, size: 36, color: color)),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4),
                icon: Icon(buttonIcon),
                label: Text(buttonText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                onPressed: onPressed,
              ),
            )
          ],
        ),
      ),
    );
  }
}
