import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final int currentGoal;
  final int currentThreshold;
  final String selectedLibrary;
  final String selectedLevel;
  final List<String> availableLibraries;
  final Function(int, int, String, String) onSaveSettings;

  const SettingsScreen({
    super.key, 
    required this.currentGoal, 
    required this.currentThreshold, 
    required this.selectedLibrary,
    required this.selectedLevel,
    required this.availableLibraries,
    required this.onSaveSettings
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
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 80.0), // Butonu yukarı kaldırmak için alt boşluk
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
              min: 5,
              max: 100,
              divisions: 19,
              label: _goalValue.toInt().toString(),
              activeColor: Colors.deepPurple,
              onChanged: (val) => setState(() => _goalValue = val),
            ),
            
            const SizedBox(height: 20),
            
            Text("Quiz Ezber Eşiği (Doğru Sayısı): ${_thresholdValue.toInt()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Kelimenin 'Öğrenildi' sayılması için quiz'de üst üste kaç kez doğru bilinmesi gerektiğini belirler.", style: TextStyle(color: Colors.grey, fontSize: 12)),
            Slider(
              value: _thresholdValue,
              min: 1,
              max: 20,
              divisions: 19,
              label: _thresholdValue.toInt().toString(),
              activeColor: Colors.orange,
              onChanged: (val) => setState(() => _thresholdValue = val),
            ),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16), 
                  backgroundColor: Colors.green, 
                  foregroundColor: Colors.white,
                  elevation: 5,
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
