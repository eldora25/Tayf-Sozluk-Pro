import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../models.dart';

class ImportWizardScreen extends StatefulWidget {
  final PlatformFile file;
  final List<String> availableLibraries;
  final Future<List<WordModel>> Function(PlatformFile) onParseFile;
  final Function(List<WordModel>, String, String) onImportConfirmed;

  const ImportWizardScreen({
    super.key,
    required this.file,
    required this.availableLibraries,
    required this.onParseFile,
    required this.onImportConfirmed,
  });

  @override
  State<ImportWizardScreen> createState() => _ImportWizardScreenState();
}

class _ImportWizardScreenState extends State<ImportWizardScreen> {
  bool _isParsing = true;
  List<WordModel> _parsedWords = [];
  String _selectedLibrary = 'Varsayılan';
  String _selectedLevel = 'Genel';
  late List<String> _safeLibraries;

  @override
  void initState() {
    super.initState();
    _safeLibraries = List.from(widget.availableLibraries);
    _safeLibraries.remove('WordNet Veritabanı');
    _safeLibraries.remove('Tekrarlanması Gerekenler');
    if (_safeLibraries.isEmpty) _safeLibraries.add('Varsayılan');
    _selectedLibrary = _safeLibraries.first;
    
    _startParsing();
  }

  Future<void> _startParsing() async {
    try {
      final words = await widget.onParseFile(widget.file);
      setState(() {
        _parsedWords = words;
        _isParsing = false;
      });
    } catch (e) {
      setState(() {
        _isParsing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dosya okunamadı veya hatalı format!"), backgroundColor: Colors.red));
      }
    }
  }

  void _showNewLibraryDialog() async {
    TextEditingController newLibCtrl = TextEditingController();
    String? newLibName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Yeni Kütüphane", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: newLibCtrl,
          decoration: InputDecoration(
            hintText: "Kütüphane adını girin", 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Theme.of(context).primaryColor.withOpacity(0.05),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (newLibCtrl.text.trim().isNotEmpty) {
                Navigator.pop(context, newLibCtrl.text.trim());
              }
            }, 
            child: const Text("Oluştur", style: TextStyle(fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (newLibName != null && newLibName.isNotEmpty) {
      setState(() {
        if (!_safeLibraries.contains(newLibName)) {
          _safeLibraries.add(newLibName);
        }
        _selectedLibrary = newLibName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("İçe Aktarma Sihirbazı", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isParsing 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Theme.of(context).primaryColor),
                const SizedBox(height: 16),
                const Text("Dosya analiz ediliyor...\nLütfen bekleyin.", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )
        : _parsedWords.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 80),
                    const SizedBox(height: 16),
                    const Text("Bu dosyada geçerli kelime bulunamadı.\nFormatı kontrol edin.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Geri Dön"))
                  ],
                ),
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2)))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.file_present, color: Colors.blue)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Dosya Adı:", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)), Text(widget.file.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)])),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.withOpacity(0.3))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Tespit Edilen Kelime:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)), Text("${_parsedWords.length} Adet", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green))])),
                        const SizedBox(height: 20),
                        const Text("Aktarım Hedefi", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedLibrary,
                                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Theme.of(context).scaffoldBackgroundColor),
                                items: _safeLibraries.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (v) => setState(() => _selectedLibrary = v!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(height: 55, width: 55, decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: IconButton(icon: Icon(Icons.add, color: Theme.of(context).primaryColor), onPressed: _showNewLibraryDialog)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedLevel,
                          decoration: InputDecoration(labelText: "Zorluk", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Theme.of(context).scaffoldBackgroundColor),
                          items: ['A1','A2','B1','B2','C1','C2','Genel'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() => _selectedLevel = v!),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    color: Theme.of(context).primaryColor.withOpacity(0.05),
                    child: const Text("ÖNİZLEME (İlk 10 Kelime)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: min(10, _parsedWords.length),
                      itemBuilder: (context, index) {
                        WordModel w = _parsedWords[index];
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1), child: Text("${index + 1}", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12))),
                          title: Text(w.word, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(w.meanings.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      }
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 20 + MediaQuery.of(context).padding.bottom),
                    decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text("İÇE AKTARIMI BAŞLAT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          widget.onImportConfirmed(_parsedWords, _selectedLibrary, _selectedLevel);
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
