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

  final List<Color> _themeColors = [
    Colors.grey.shade900, 
    Colors.grey.shade300, 
    Colors.blue, 
    Colors.teal, 
    Colors.deepPurpleAccent, 
    Colors.deepOrangeAccent, 
    Colors.pinkAccent, 
    Colors.cyan 
  ];

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 22),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ayarlar & Temalar", style: TextStyle(fontWeight: FontWeight.bold)), elevation: 0),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 120.0 + MediaQuery.of(context).padding.bottom),
            children: [
              _buildSectionTitle("Görünüm & Tema", Icons.palette),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Tema Rengini Seçin", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: List.generate(_themeColors.length, (index) {
                          bool isSelected = _themeIndex == index;
                          return GestureDetector(
                            onTap: () => setState(() => _themeIndex = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              margin: const EdgeInsets.only(right: 16),
                              height: isSelected ? 56 : 48,
                              width: isSelected ? 56 : 48,
                              decoration: BoxDecoration(
                                color: _themeColors[index],
                                shape: BoxShape.circle,
                                border: isSelected ? Border.all(color: Theme.of(context).primaryColor, width: 3) : Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                                boxShadow: isSelected ? [BoxShadow(color: _themeColors[index].withOpacity(0.4), blurRadius: 10, spreadRadius: 2)] : [],
                              ),
                              child: isSelected ? Icon(Icons.check, color: index == 1 ? Colors.black : Colors.white, size: 28) : null,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                )
              ),

              _buildSectionTitle("Kütüphane Yönetimi", Icons.library_books),
              _buildCard(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _library,
                      decoration: InputDecoration(labelText: "Aktif Kütüphane", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Theme.of(context).scaffoldBackgroundColor),
                      items: widget.availableLibraries.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _library = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _level,
                      decoration: InputDecoration(labelText: "Zorluk Seviyesi", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Theme.of(context).scaffoldBackgroundColor),
                      items: ['A1','A2','B1','B2','C1','C2','Genel'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _level = v!),
                    ),
                  ],
                ),
              ),
              
              _buildSectionTitle("Hedefler ve Öğrenme", Icons.track_changes),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Günlük Öğrenme Hedefi:", style: TextStyle(fontWeight: FontWeight.bold)), Text("${_goalValue.toInt()} Kelime", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 16))]),
                    Slider(value: _goalValue, min: 5, max: 100, divisions: 19, activeColor: Theme.of(context).primaryColor, onChanged: (val) => setState(() => _goalValue = val)),
                    const Divider(height: 30),
                    
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Quiz Soru Sayısı:", style: TextStyle(fontWeight: FontWeight.bold)), Text("${_questionCountValue.toInt()} Soru", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16))]),
                    const Text("Bir quiz seansında çıkacak soru sayısı.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Slider(value: _questionCountValue, min: 5, max: 100, divisions: 19, activeColor: Colors.blue, onChanged: (val) => setState(() => _questionCountValue = val)),
                    const Divider(height: 30),

                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Quiz Ezber Eşiği:", style: TextStyle(fontWeight: FontWeight.bold)), Text("${_thresholdValue.toInt()} Doğru", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16))]),
                    const Text("Bir kelimenin 'Öğrenildi' (Mezun) sayılması için üst üste bilinmesi gereken sayı.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Slider(value: _thresholdValue, min: 2, max: 50, divisions: 48, activeColor: Colors.orange, onChanged: (val) => setState(() => _thresholdValue = val)),
                  ],
                )
              ),
              
              _buildSectionTitle("Uygulama İçi Hazır Paketler", Icons.cloud_download),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Boyutu büyük paketlerin yüklenmesi birkaç saniye sürebilir.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 16),
                    ListTile(tileColor: Colors.indigo.withOpacity(0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), title: const Text("WordNet İngilizce", style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text("Kapsamlı İng-İng Sözlük"), trailing: const Icon(Icons.download_for_offline, color: Colors.indigo, size: 32), onTap: () { _showWordNetAlert(); }),
                    const SizedBox(height: 10),
                    ListTile(tileColor: Colors.orange.withOpacity(0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), title: const Text("Tayf İngilizce-Türkçe", style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text("Kısa Temel Kelimeler"), trailing: const Icon(Icons.download_for_offline, color: Colors.orange, size: 32), onTap: () { widget.onAddPackage("assets/EN-TR_tayf.txt", "txt", "Tayf İng-Tr"); }),
                    const SizedBox(height: 10),
                    ListTile(tileColor: Colors.green.withOpacity(0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), title: const Text("Babylon İngilizce-Türkçe", style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text("Geniş Kapsamlı Sözlük"), trailing: const Icon(Icons.download_for_offline, color: Colors.green, size: 32), onTap: () { widget.onAddPackage("assets/Babylon_English_Turkish_donustu.csv", "csv", "Babylon İng-Tr"); }),
                    const SizedBox(height: 10),
                    ListTile(tileColor: Colors.red.withOpacity(0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), title: const Text("Babylon Türkçe-İngilizce", style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text("Geniş Kapsamlı Sözlük"), trailing: const Icon(Icons.download_for_offline, color: Colors.red, size: 32), onTap: () { widget.onAddPackage("assets/Babylon_Turkish_English_donustu.csv", "csv", "Babylon Tr-İng"); }),
                    const SizedBox(height: 10),
                    ListTile(tileColor: Colors.blue.withOpacity(0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), title: const Text("Test Paketi", style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text("Örnek cümleli test verisi"), trailing: const Icon(Icons.download_for_offline, color: Colors.blue, size: 32), onTap: () { widget.onAddPackage("assets/test_paket.json", "json", "Test Paketi"); }),
                    const SizedBox(height: 10),
                    ListTile(tileColor: Colors.purple.withOpacity(0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), title: const Text("FreeDict İngilizce-Türkçe", style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text("Açık Kaynak Sözlük"), trailing: const Icon(Icons.download_for_offline, color: Colors.purple, size: 32), onTap: () { widget.onAddPackage("assets/Free-KH.txt", "txt", "Free-KH İng-Tr"); }),
                  ],
                )
              ),
            ],
          ),

          // YENİ: Yapışkanlı Sabit Kaydet Butonu (Floating Bottom Bar)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 16 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded),
                label: const Text("AYARLARI KAYDET", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white, elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                onPressed: () {
                  widget.onSaveSettings(_goalValue.toInt(), _thresholdValue.toInt(), _questionCountValue.toInt(), _themeIndex, _library, _level);
                  Navigator.pop(context);
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
