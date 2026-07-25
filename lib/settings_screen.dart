import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final int currentGoal;
  final int currentThreshold;
  final String selectedLibrary;
  final String selectedLevel;
  final List<String> availableLibraries;
  final Function(int, int, String, String) onSaveSettings;
  final Function(String, String, String) onAddPackage; // assetPath, extension, libraryName

  const SettingsScreen({
    super.key, 
    required this.currentGoal, 
    required this.currentThreshold, 
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
  late String _library;
  late String _level;

  @override
  void initState() {
    super.initState();
    _goalValue = widget.currentGoal.toDouble();
    _thresholdValue = widget.currentThreshold.toDouble();
    _library = widget.availableLibraries.contains(widget.selectedLibrary) 
        ? widget.selectedLibrary 
        : widget.availableLibraries.first;
    _level = widget.selectedLevel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ayarlar")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 80.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              value: _goalValue,
              min: 5, max: 100, divisions: 19,
              label: _goalValue.toInt().toString(),
              activeColor: Colors.deepPurple,
              onChanged: (val) => setState(() => _goalValue = val),
            ),
            const SizedBox(height: 20),
            Text("Quiz Ezber Eşiği (Doğru Sayısı): ${_thresholdValue.toInt()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Kelimenin 'Öğrenildi' sayılması için gerekli doğru sayısı.", style: TextStyle(color: Colors.grey, fontSize: 12)),
            Slider(
              value: _thresholdValue,
              min: 1, max: 20, divisions: 19,
              label: _thresholdValue.toInt().toString(),
              activeColor: Colors.orange,
              onChanged: (val) => setState(() => _thresholdValue = val),
            ),
            
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
            
            const Text("Uygulama İçi Hazır Paketler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const Text("Boyutu büyük paketlerin yüklenmesi birkaç saniye sürebilir, lütfen bekleyin.", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 10),
            
            // 1. JSON Paketi
            ListTile(
              tileColor: Colors.blue.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: const Text("Test Paketi", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Örnek cümleli (JSON)"),
              trailing: const Icon(Icons.download, color: Colors.blue),
              onTap: () {
                widget.onAddPackage("assets/test_paket.json", "json", "Test Paketi");
              },
            ),
            const SizedBox(height: 10),

            // 2. Txt Paketi
            ListTile(
              tileColor: Colors.orange.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: const Text("Tayf İngilizce-Türkçe", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Kısa Temel Kelimeler (TXT)"),
              trailing: const Icon(Icons.download, color: Colors.orange),
              onTap: () {
                widget.onAddPackage("assets/EN-TR_tayf.txt", "txt", "Tayf İng-Tr");
              },
            ),
            const SizedBox(height: 10),

            // 3. Babylon İng-Tr
            ListTile(
              tileColor: Colors.green.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: const Text("Babylon İngilizce-Türkçe", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Geniş Kapsamlı Sözlük (CSV)"),
              trailing: const Icon(Icons.download, color: Colors.green),
              onTap: () {
                widget.onAddPackage("assets/Babylon_English_Turkish_donustu.csv", "csv", "Babylon İng-Tr");
              },
            ),
            const SizedBox(height: 10),

            // 4. Babylon Tr-İng
            ListTile(
              tileColor: Colors.red.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: const Text("Babylon Türkçe-İngilizce", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Geniş Kapsamlı Sözlük (CSV)"),
              trailing: const Icon(Icons.download, color: Colors.red),
              onTap: () {
                widget.onAddPackage("assets/Babylon_Turkish_English_donustu.csv", "csv", "Babylon Tr-İng");
              },
            ),

            const SizedBox(height: 40),
             // 5. Free Txt Paketi
            ListTile(
              tileColor: Colors.deepPurple.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: const Text("Tayf İngilizce-Türkçe", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Free Eng-TR (TXT)"),
              trailing: const Icon(Icons.download, color: Colors.orange),
              onTap: () {
                widget.onAddPackage("assets/Free-KH.txt", "txt", "Free-KH İng-Tr");
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, elevation: 5,
                ),
                onPressed: () {
                  widget.onSaveSettings(_goalValue.toInt(), _thresholdValue.toInt(), _library, _level);
                  Navigator.pop(context);
                },
                child: const Text("AYARLARI KAYDET", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
