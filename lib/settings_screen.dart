import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'core/db_helper.dart';
import 'core/tts_manager.dart';

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
  
  late List<String> _safeLibraries;

  final List<Color> _themeColors = [
    Colors.grey.shade900, Colors.grey.shade300, Colors.blue, Colors.teal,                  
    Colors.deepPurpleAccent, Colors.deepOrangeAccent, Colors.pinkAccent, Colors.cyan,                  
    const Color(0xFF2C3E50), const Color(0xFFB0BEC5), const Color(0xFFF4ECD8), const Color(0xFFE8F4F8),      
    const Color(0xFFF5F5DC), const Color(0xFF4E342E), const Color(0xFF37474F), const Color(0xFF558B2F),      
  ];

  final List<String> _themeNames = [
    "Gece Siyahı (Koyu)", "Sade Aydınlık (Açık)", "Deniz Mavisi", "Nane Yeşili",
    "Canlı Mor", "Sıcak Turuncu", "Şeker Pembe", "Okyanus Esintisi",
    "Koyu Gri / Gece", "Açık Gri / Gümüş", "Sıcak Kağıt", "Soğuk Kağıt",
    "Krem Kağıt", "Sıcak Çikolata", "Kömür Karası", "Mat Doğal Yeşil"
  ];

  @override
  void initState() {
    super.initState();
    
    _safeLibraries = widget.availableLibraries.toSet().toList();
    if (_safeLibraries.isEmpty) {
      _safeLibraries = ['Varsayılan'];
    }

    _goalValue = widget.currentGoal.toDouble().clamp(5.0, 100.0);
    _thresholdValue = widget.currentThreshold.toDouble().clamp(2.0, 50.0);
    _questionCountValue = widget.currentQuestionCount.toDouble().clamp(5.0, 100.0);
    _themeIndex = widget.currentThemeIndex.clamp(0, _themeNames.length - 1);
    
    _library = _safeLibraries.contains(widget.selectedLibrary) 
        ? widget.selectedLibrary 
        : _safeLibraries.first;
        
    _level = widget.selectedLevel;
    if (!['A1','A2','B1','B2','C1','C2','Genel'].contains(_level)) {
      _level = 'Genel';
    }
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
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 120.0 + MediaQuery.of(context).padding.bottom),
            children: [
              _buildSectionTitle("Görünüm & Tema", Icons.palette),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("Tema Rengi Seçimi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      _themeNames[_themeIndex], 
                      style: TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.bold, 
                        color: Theme.of(context).primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: List.generate(_themeColors.length, (index) {
                        bool isSelected = _themeIndex == index;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _themeIndex = index);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut, 
                            height: isSelected ? 50 : 42,
                            width: isSelected ? 50 : 42,
                            decoration: BoxDecoration(
                              color: _themeColors[index],
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Theme.of(context).primaryColor, width: 3) : Border.all(color: Colors.grey.withOpacity(0.4), width: 1),
                              boxShadow: isSelected 
                                  ? [BoxShadow(color: _themeColors[index].withOpacity(0.5), blurRadius: 10.0, spreadRadius: 2.0)] 
                                  : const [],
                            ),
                            child: isSelected ? Icon(Icons.check, color: (index == 1 || index >= 9 && index <= 12) ? Colors.black : Colors.white, size: 26) : null,
                          ),
                        );
                      }),
                    ),
                  ],
                )
              ),

              _buildSectionTitle("Kütüphane Yönetimi", Icons.library_books),
              _buildCard(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true, 
                      value: _library,
                      decoration: InputDecoration(labelText: "Aktif Kütüphane", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Theme.of(context).scaffoldBackgroundColor),
                      items: _safeLibraries.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => _library = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true, 
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                        const Expanded(child: Text("Günlük Öğrenme Hedefi:", style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)), 
                        const SizedBox(width: 8),
                        Text("${_goalValue.toInt()} Kelime", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 16))
                      ]
                    ),
                    Slider(value: _goalValue, min: 5, max: 100, divisions: 19, activeColor: Theme.of(context).primaryColor, onChanged: (val) => setState(() => _goalValue = val)),
                    const Divider(height: 30),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                        const Expanded(child: Text("Quiz Soru Sayısı:", style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)), 
                        const SizedBox(width: 8),
                        Text("${_questionCountValue.toInt()} Soru", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16))
                      ]
                    ),
                    const Text("Bir quiz seansında çıkacak soru sayısı.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Slider(value: _questionCountValue, min: 5, max: 100, divisions: 19, activeColor: Colors.blue, onChanged: (val) => setState(() => _questionCountValue = val)),
                    const Divider(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                        const Expanded(child: Text("Quiz Ezber Eşiği:", style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)), 
                        const SizedBox(width: 8),
                        Text("${_thresholdValue.toInt()} Doğru", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16))
                      ]
                    ),
                    const Text("Bir kelimenin Quiz'den çıkıp SRS (Aralıklı Tekrar) sistemine dahil olması için üst üste doğru bilinmesi gereken sayı.", style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                    ListTile(tileColor: Colors.indigo.withOpacity(0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), title: const Text("WordNet Veritabanı (Aktif)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)), subtitle: const Text("150.000+ kelimelik devasa sözlük Isar veritabanına kalıcı olarak yüklendi. 'Aktif Kütüphane' menüsünden seçebilirsiniz."), trailing: const Icon(Icons.check_circle, color: Colors.indigo, size: 32)),
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
                  HapticFeedback.heavyImpact();
                  final g = _goalValue.toInt();
                  final t = _thresholdValue.toInt();
                  final qc = _questionCountValue.toInt();
                  final ti = _themeIndex;
                  final lib = _library;
                  final lvl = _level;
                  
                  Navigator.pop(context);
                  
                  Future.delayed(const Duration(milliseconds: 150), () {
                    widget.onSaveSettings(g, t, qc, ti, lib, lvl);
                  });
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
