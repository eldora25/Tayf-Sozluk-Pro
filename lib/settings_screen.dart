import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final int currentGoal;
  final int currentThreshold;
  final Function(int, int) onSaveSettings;

  const SettingsScreen({
    super.key, 
    required this.currentGoal, 
    required this.currentThreshold, 
    required this.onSaveSettings
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _goalValue;
  late double _thresholdValue;

  @override
  void initState() {
    super.initState();
    _goalValue = widget.currentGoal.toDouble();
    _thresholdValue = widget.currentThreshold.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ayarlar")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 40),
            
            Text("Quiz Ezber Eşiği (Doğru Sayısı): ${_thresholdValue.toInt()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Bir kelimenin 'Öğrenildi' sayılması için quiz'de üst üste kaç kez doğru bilinmesi gerektiğini belirler.", style: TextStyle(color: Colors.grey, fontSize: 12)),
            Slider(
              value: _thresholdValue,
              min: 1,
              max: 20,
              divisions: 19,
              label: _thresholdValue.toInt().toString(),
              activeColor: Colors.orange,
              onChanged: (val) => setState(() => _thresholdValue = val),
            ),
            
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () {
                  widget.onSaveSettings(_goalValue.toInt(), _thresholdValue.toInt());
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
