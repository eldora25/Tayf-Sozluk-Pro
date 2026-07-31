import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'models.dart';

class LibraryManagerScreen extends StatefulWidget {
  final List<WordModel> allWords;
  final List<WordModel> learningWords; 
  final List<WordModel> toRepeatWords; 
  final List<WordModel> learnedWords;
  final List<WordModel> wrongWords;
  final Function(String, String) onRename;
  final Function(String) onDelete;
  final Function(String) onExport;

  const LibraryManagerScreen({
    super.key,
    required this.allWords,
    required this.learningWords,
    required this.toRepeatWords,
    required this.learnedWords,
    required this.wrongWords,
    required this.onRename,
    required this.onDelete,
    required this.onExport,
  });

  @override
  State<LibraryManagerScreen> createState() => _LibraryManagerScreenState();
}

class _LibraryManagerScreenState extends State<LibraryManagerScreen> {
  bool _isDownloading = false;

  List<String> get _libraries {
    Set<String> libs = {};
    libs.addAll(widget.allWords.map((e) => e.libraryName));
    libs.addAll(widget.learnedWords.map((e) => e.libraryName));
    libs.addAll(widget.toRepeatWords.map((e) => e.libraryName));
    libs.addAll(widget.learningWords.map((e) => e.libraryName));
    libs.remove('Tekrarlanması Gerekenler'); 
    return libs.toList();
  }

  void _showEditDialog(String oldName) {
    TextEditingController ctrl = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kütüphane Adını Değiştir"),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: "Yeni Ad")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                widget.onRename(oldName, ctrl.text.trim());
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(String libName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kütüphaneyi Sil", style: TextStyle(color: Colors.red)),
        content: Text("'$libName' kütüphanesini ve içindeki tüm kelimeleri kalıcı olarak silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              widget.onDelete(libName);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("SİL"),
          ),
        ],
      ),
    );
  }

  // YENİ: Topluluğa Önerme Fonksiyonu
  Future<void> _submitToCommunity(String libName) async {
    try {
      List<WordModel> wordsToExport = [
        ...widget.allWords.where((w) => w.libraryName == libName),
        ...widget.learningWords.where((w) => w.libraryName == libName),
        ...widget.toRepeatWords.where((w) => w.libraryName == libName),
        ...widget.learnedWords.where((w) => w.libraryName == libName),
      ];

      if (wordsToExport.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bu kütüphane boş.")));
        return;
      }

      // JSON formatına dönüştür
      List<Map<String, dynamic>> jsonData = wordsToExport.map((w) => {
        "word": w.word,
        "meanings": w.meanings,
        "examples": w.examples,
        "level": w.level,
        "libraryName": "User_Recommended", // Havuzda karışmaması için
      }).toList();

      String jsonString = json.encode(jsonData);

      // Geçici dosya oluştur
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/community_submission_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      // E-posta ile paylaşım
      if (mounted) {
        Navigator.pop(context); // Menüyü kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Dosya hazırlandı. E-posta uygulamanızı seçin."), backgroundColor: Colors.green)
        );
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        text: "Merhaba Tayfun,\n\nEkte hazırladığım sözlük kütüphanesini 'Topluluk Kütüphanesi' havuzuna eklenmesi için gönderiyorum.\n\nKütüphane Adı: $libName\nKelime Sayısı: ${wordsToExport.length}",
        subject: "Yeni Topluluk Kütüphanesi Önerisi"
      );
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
    }
  }

  // YENİ: GitHub'dan Topluluk Kütüphanesini İndirme
  Future<void> _downloadCommunityLibrary() async {
    setState(() => _isDownloading = true);
    try {
      // DİKKAT: Buradaki URL'yi kendi deponuzun RAW URL'si ile DEĞİŞTİRİN
      // Örnek: https://raw.githubusercontent.com/eldora25/Tayf-Sozluk-Pro/main/assets/user_recommended_library.json
      final String rawUrl = 'https://raw.githubusercontent.com/eldora25/Tayf-Sozluk-Pro/main/assets/user_recommended_library.json'; 
      
      final response = await http.get(Uri.parse(rawUrl));

      if (response.statusCode == 200) {
        // Dosyayı geçici dizine kaydet
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/Topluluk_Kutuphanesi.json');
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İndirme başarılı! İçe aktarılıyor..."), backgroundColor: Colors.green));
           // (Burada ileride dosyayı doğrudan sisteme okutacak fonksiyonu tetikleyebilirsiniz)
        }
      } else {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sözlük bulunamadı veya ağ hatası. Kod: ${response.statusCode}"), backgroundColor: Colors.orange));
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isDownloading = false);
    }
  }


  void _showLibraryMenu(String libName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text("Adını Değiştir"),
              onTap: () { Navigator.pop(context); _showEditDialog(libName); },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: const Text("Dışa Aktar / Paylaş"),
              onTap: () { Navigator.pop(context); widget.onExport(libName); },
            ),
            // YENİ BUTON: TOPLULUĞA GÖNDER
            ListTile(
              leading: const Icon(Icons.public, color: Colors.deepPurple),
              title: const Text("Topluluğa Öner", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              subtitle: const Text("Bu kütüphaneyi ana havuza gönder"),
              onTap: () => _submitToCommunity(libName),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Kütüphaneyi Sil"),
              onTap: () { Navigator.pop(context); _showDeleteConfirm(libName); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var libs = _libraries;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kütüphane Yönetimi"),
        actions: [
          // YENİ: ÜST BARA TOPLULUK KÜTÜPHANESİ İNDİRME BUTONU EKLENDİ
           IconButton(
            tooltip: "Topluluk Kütüphanesini İndir",
            icon: _isDownloading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.cloud_download),
            onPressed: _isDownloading ? null : _downloadCommunityLibrary,
          )
        ],
      ),
      body: libs.isEmpty
          ? const Center(child: Text("Kayıtlı kütüphane bulunamadı."))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: libs.length,
              itemBuilder: (context, index) {
                String libName = libs[index];
                int total = widget.allWords.where((e) => e.libraryName == libName).length +
                            widget.learnedWords.where((e) => e.libraryName == libName).length +
                            widget.learningWords.where((e) => e.libraryName == libName).length +
                            widget.toRepeatWords.where((e) => e.libraryName == libName).length;
                            
                int learned = widget.learnedWords.where((e) => e.libraryName == libName).length;
                int wrong = widget.wrongWords.where((e) => e.libraryName == libName).fold(0, (a, b) => a + b.wrongCount);
                
                double progress = total > 0 ? (learned / total) : 0;

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    onTap: () => _showLibraryMenu(libName),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(libName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple), overflow: TextOverflow.ellipsis),
                              ),
                              IconButton(
                                icon: const Icon(Icons.settings, color: Colors.grey),
                                onPressed: () => _showLibraryMenu(libName),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Toplam: $total", style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 16),
                                Text("Öğrenilen: $learned", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 16),
                                Text("Yanlış: $wrong", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[300],
                            color: Colors.green,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
