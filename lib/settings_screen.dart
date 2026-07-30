import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final int currentGoal;
  final int currentThreshold;
  final int currentQuestionCount;
  final int currentThemeIndex;
  final String selectedLibrary;
  final String selectedLevel;
  final List<String> availableLibraries;
  final Function(int, int, int, int, String, String) onSaveSettings;
  final Function(String, String, String) onAddPackage; 

  const SettingsScreen({
    super.key, 
    required this.currentGoal, 
    required this.currentThreshold, 
    required this.currentQuestionCount,
    required this.currentThemeIndex,
    required this.selectedLibrary,
    required this.selectedLevel,
    required this.availableLibraries,
    required this.onSaveSettings,
    required this.onAddPackage,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _goalValue;
  late double _thresholdValue;
  late double _questionCountValue;
  late int _themeIndex;
  late String _library;
  late String _level;

  @override
  void initState() {
    super.initState();
    _goalValue = widget.currentGoal.toDouble();
    _thresholdValue = widget.currentThreshold.toDouble();
    _questionCountValue = widget.currentQuestionCount.toDouble();
    _themeIndex = widget.currentThemeIndex;
    _library = widget.availableLibraries.contains(widget.selectedLibrary) 
        ? widget.selectedLibrary 
        : widget.availableLibraries.first;
    _level = widget.selectedLevel;
  }

  void _showWordNetAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.code, color: Colors.indigo, size: 70),
            const SizedBox(height: 16),
            const Text("WordNet Kütüphanesi", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 12),
            const Text("Yazılımcı halen çalışıyor... 😅\n\nÇok yakında harika bir İngilizce-İngilizce sözlük deneyimiyle karşınızda olacak!", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, height: 1.4)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Anladım", style: TextStyle(fontWeight: FontWeight.bold))
            )
          ]
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ayarlar & Temalar")),
      body: ListView(
        // ALT BUTON GÜVENLİK BOŞLUĞU DİNAMİK OLARAK EKLENDİ
        padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 120.0 + MediaQuery.of(context).padding.bottom),
        children: [
          const Text("Görünüm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: _themeIndex,
            decoration: const InputDecoration(labelText: "Tema Seçimi", border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 0, child: Text("Karanlık Mod (Varsayılan)")),
              DropdownMenuItem(value: 1, child: Text("Aydınlık Mod")),
              DropdownMenuItem(value: 2, child: Text("Pastel Mavi (Okuması Kolay)")),
              DropdownMenuItem(value: 3, child: Text("Pastel Yeşil (Dinlendirici)")),
              DropdownMenuItem(value: 4, child: Text("Canlı Mor (Enerjik)")),
              DropdownMenuItem(value: 5, child: Text("Sıcak Turuncu (Canlı)")),
              DropdownMenuItem(value: 6, child: Text("Şeker Pembe (Tatlı)")), 
              DropdownMenuItem(value: 7, child: Text("Rengarenk (Eğlenceli)")), 
            ],
            onChanged: (v) => setState(() => _themeIndex = v!),
          ),
          
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),

          const Text("Kütüphane ve Seviye", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _library,
            decoration: const InputDecoration(labelText: "Aktif Kütüphane Seç", border: OutlineInputBorder()),
            items: widget.availableLibraries.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _library = v!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _level,
            decoration: const InputDecoration(labelText: "Seviye Seç", border: OutlineInputBorder()),
            items: ['A1','A2','B1','B2','C1','C2','Genel'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _level = v!),
          ),
          
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
          
          Text("Günlük Öğrenme Hedefi: ${_goalValue.toInt()} Kelime", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Slider(
            value: _goalValue, min: 5, max: 100, divisions: 19,
            label: _goalValue.toInt().toString(), activeColor: Colors.deepPurple,
            onChanged: (val) => setState(() => _goalValue = val),
          ),
          const SizedBox(height: 20),
          Text("Quiz Soru Sayısı: ${_questionCountValue.toInt()} Soru", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("Bir quiz seansında kaç soru çıkacağını belirler.", style: TextStyle(color: Colors.grey, fontSize: 12)),
          Slider(
            value: _questionCountValue, min: 5, max: 100, divisions: 19,
            label: _questionCountValue.toInt().toString(), activeColor: Colors.blue,
            onChanged: (val) => setState(() => _questionCountValue = val),
          ),
          const SizedBox(height: 20),
          Text("Quiz Ezber Eşiği (Doğru Sayısı): ${_thresholdValue.toInt()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("Kelimenin 'Öğrenildi' sayılması için gerekli doğru sayısı (Min: 2, Max: 50).", style: TextStyle(color: Colors.grey, fontSize: 12)),
          Slider(
            value: _thresholdValue, min: 2, max: 50, divisions: 48,
            label: _thresholdValue.toInt().toString(), activeColor: Colors.orange,
            onChanged: (val) => setState(() => _thresholdValue = val),
          ),
          
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
          
          const Text("Uygulama İçi Hazır Paketler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          const Text("Boyutu büyük paketlerin yüklenmesi birkaç saniye sürebilir, lütfen bekleyin.", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 10),
          
          ListTile(
            tileColor: Colors.indigo.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            title: const Text("WordNet İngilizce", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Kapsamlı İng-İng Sözlük (JSON)"),
            trailing: const Icon(Icons.download, color: Colors.indigo),
            onTap: () { _showWordNetAlert(); },
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.orange.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            title: const Text("Tayf İngilizce-Türkçe", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Kısa Temel Kelimeler (TXT)"),
            trailing: const Icon(Icons.download, color: Colors.orange),
            onTap: () { widget.onAddPackage("assets/EN-TR_tayf.txt", "txt", "Tayf İng-Tr"); },
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.green.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            title: const Text("Babylon İngilizce-Türkçe", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Geniş Kapsamlı Sözlük (CSV)"),
            trailing: const Icon(Icons.download, color: Colors.green),
            onTap: () { widget.onAddPackage("assets/Babylon_English_Turkish_donustu.csv", "csv", "Babylon İng-Tr"); },
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.red.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            title: const Text("Babylon Türkçe-İngilizce", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Geniş Kapsamlı Sözlük (CSV)"),
            trailing: const Icon(Icons.download, color: Colors.red),
            onTap: () { widget.onAddPackage("assets/Babylon_Turkish_English_donustu.csv", "csv", "Babylon Tr-İng"); },
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.blue.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            title: const Text("Test Paketi", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Örnek cümleli test verisi (JSON)"),
            trailing: const Icon(Icons.download, color: Colors.blue),
            onTap: () { widget.onAddPackage("assets/test_paket.json", "json", "Test Paketi"); },
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.purple.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            title: const Text("FreeDict İngilizce-Türkçe", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Açık Kaynak Sözlük (TXT)"),
            trailing: const Icon(Icons.download, color: Colors.purple),
            onTap: () { widget.onAddPackage("assets/Free-KH.txt", "txt", "Free-KH İng-Tr"); },
          ),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, elevation: 5,
              ),
              onPressed: () {
                widget.onSaveSettings(_goalValue.toInt(), _thresholdValue.toInt(), _questionCountValue.toInt(), _themeIndex, _library, _level);
                Navigator.pop(context);
              },
              child: const Text("AYARLARI KAYDET", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
