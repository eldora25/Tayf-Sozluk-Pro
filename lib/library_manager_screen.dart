import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'main.dart'; // parseLibraryDataInBackground fonksiyonuna erişim için

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Adını Değiştir", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl, 
          decoration: InputDecoration(
            labelText: "Yeni Ad",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Theme.of(context).primaryColor.withOpacity(0.05),
          )
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                widget.onRename(oldName, ctrl.text.trim());
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text("Kaydet", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(String libName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Kalıcı Olarak Sil", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text("'$libName' kütüphanesini ve içindeki tüm kelimeleri kalıcı olarak silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              widget.onDelete(libName);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("SİL", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // DÜZELTİLDİ: Dışa aktarma işlemi senkronizasyon hatalarına karşı güçlendirildi
  Future<void> _handleExport(String libName) async {
    Navigator.pop(context); // Önce menüyü kapat
    
    // UI'ın rahatlaması için ufak bir bekleme
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$libName dışa aktarılıyor, bekleyin..."), duration: const Duration(seconds: 2))
    );
    
    await widget.onExport(libName);
  }

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

      List<Map<String, dynamic>> jsonData = wordsToExport.map((w) => {
        "word": w.word,
        "meanings": w.meanings,
        "examples": w.examples,
        "level": w.level,
        "libraryName": "Topluluk_Onerisi", // DÜZELTİLDİ: Karışmaması için standartlaştırıldı
      }).toList();

      String jsonString = json.encode(jsonData);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/community_submission_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      if (mounted) {
        Navigator.pop(context); 
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

  // DÜZELTİLDİ: Dosya indirildikten sonra gerçek içe aktarma (parse) işlemi eklendi!
  Future<void> _downloadCommunityLibrary() async {
    setState(() => _isDownloading = true);
    try {
      final String rawUrl = 'https://raw.githubusercontent.com/eldora25/Tayf-Sozluk-Pro/main/assets/user_recommended_library.json'; 
      
      final response = await http.get(Uri.parse(rawUrl));

      if (response.statusCode == 200) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İndirme başarılı! İçerik çözümleniyor..."), backgroundColor: Colors.blue));

        // GERÇEK İÇE AKTARMA İŞLEMİ BURADA BAŞLIYOR
        String content = utf8.decode(response.bodyBytes);
        String customLibraryName = "Topluluk Kütüphanesi";
        
        final List<String> parsedJsons = await compute(parseLibraryDataInBackground, {
          'content': content, 
          'extension': 'json', 
          'libraryName': customLibraryName, 
          'originalFileName': 'user_recommended_library.json'
        });
        
        if (parsedJsons.isNotEmpty && parsedJsons.first.contains('"error":')) {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(json.decode(parsedJsons.first)['error']), backgroundColor: Colors.red));
        } else {
           // Mevcut kelimeleri mükerrer olmaması için al
           Set<String> existingWords = {
              ...widget.allWords.map((w) => w.word),
              ...widget.learnedWords.map((w) => w.word),
              ...widget.toRepeatWords.map((w) => w.word),
              ...widget.learningWords.map((w) => w.word),
           };

           List<WordModel> newWords = [];
           for (var jsonStr in parsedJsons) {
              try {
                var w = WordModel.fromJson(jsonStr)..listType = 'all';
                if (!existingWords.contains(w.word)) {
                   newWords.add(w);
                   existingWords.add(w.word); 
                }
              } catch(e) { continue; }
           }

           // Veritabanına Yaz
           if (newWords.isNotEmpty) {
             await isar.writeTxn(() async { 
                await isar.wordModels.putAll(newWords); 
             });
             
             // Arayüzü güncelle (Geri bildirimi ana sayfaya yansıtmak için listeye ekliyoruz)
             setState(() {
                widget.allWords.addAll(newWords);
             });
             
             if (mounted) {
               showDialog(
                 context: context,
                 builder: (ctx) => AlertDialog(
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                   content: Column(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       const Icon(Icons.cloud_done, color: Colors.green, size: 70),
                       const SizedBox(height: 16),
                       const Text("Harika Haber!", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                       const SizedBox(height: 12),
                       Text("Topluluk Kütüphanesi başarıyla yüklendi.\n\nSisteme tam ${newWords.length} yeni kelime eklendi!", textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.4)),
                       const SizedBox(height: 24),
                       ElevatedButton(
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                         onPressed: () => Navigator.pop(ctx),
                         child: const Text("Tamam", style: TextStyle(fontWeight: FontWeight.bold))
                       )
                     ]
                   )
                 )
               );
             }
           } else {
             if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sözlük zaten güncel. Yeni kelime bulunamadı."), backgroundColor: Colors.orange));
           }
        }
      } else {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sözlük bulunamadı veya ağ hatası. Kod: ${response.statusCode}"), backgroundColor: Colors.orange));
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }


  void _showLibraryMenu(String libName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5))]
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Wrap(
              children: [
                Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("'$libName' için Seçenekler", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.edit, color: Colors.blue)),
                  title: const Text("Adını Değiştir", style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () { Navigator.pop(context); _showEditDialog(libName); },
                ),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.share, color: Colors.green)),
                  title: const Text("Dışa Aktar / Paylaş", style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => _handleExport(libName),
                ),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.public, color: Colors.deepPurple)),
                  title: const Text("Topluluğa Öner", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  subtitle: const Text("Bu kütüphaneyi ana havuza gönder"),
                  onTap: () => _submitToCommunity(libName),
                ),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.delete, color: Colors.red)),
                  title: const Text("Kütüphaneyi Sil", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  onTap: () { Navigator.pop(context); _showDeleteConfirm(libName); },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var libs = _libraries;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            expandedHeight: 120.0,
            flexibleSpace: const FlexibleSpaceBar(
              title: Text("Kütüphaneler", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              centerTitle: false,
            ),
            actions: [
               Padding(
                 padding: const EdgeInsets.only(right: 8.0),
                 child: Container(
                   decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                   child: IconButton(
                    tooltip: "Topluluk Kütüphanesini İndir",
                    icon: _isDownloading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.cloud_download, color: Colors.white),
                    onPressed: _isDownloading ? null : _downloadCommunityLibrary,
                                   ),
                 ),
               )
            ],
          ),
          libs.isEmpty
            ? const SliverFillRemaining(
                child: Center(child: Text("Kayıtlı kütüphane bulunamadı.", style: TextStyle(color: Colors.grey, fontSize: 16))),
              )
            : SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      String libName = libs[index];
                      int total = widget.allWords.where((e) => e.libraryName == libName).length +
                                  widget.learnedWords.where((e) => e.libraryName == libName).length +
                                  widget.learningWords.where((e) => e.libraryName == libName).length +
                                  widget.toRepeatWords.where((e) => e.libraryName == libName).length;
                                  
                      int learned = widget.learnedWords.where((e) => e.libraryName == libName).length;
                      int wrong = widget.wrongWords.where((e) => e.libraryName == libName).fold(0, (a, b) => a + b.wrongCount);
                      
                      double progress = total > 0 ? (learned / total) : 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                          border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1.5)
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showLibraryMenu(libName),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Icon(Icons.menu_book, color: Colors.deepPurple, size: 24),
                                            const SizedBox(width: 10),
                                            Expanded(child: Text(libName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple), overflow: TextOverflow.ellipsis)),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.more_vert, color: Colors.grey.shade400),
                                    ],
                                  ),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Toplam: $total", style: const TextStyle(fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 16),
                                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text("Öğrenilen: $learned", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                                        const SizedBox(width: 16),
                                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text("Yanlış: $wrong", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.grey.withOpacity(0.2),
                                      color: Colors.greenAccent.shade400,
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: libs.length,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
