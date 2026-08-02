import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart'; 
import 'models.dart';
import 'main.dart'; 
import 'firebase_sync_service.dart';
import 'wordnet.dart'; // YENİ: WordNet Servisi Eklendi

class LibraryManagerScreen extends StatefulWidget {
  final List<WordModel> allWords;
  final List<WordModel> learningWords; 
  final List<WordModel> toRepeatWords; 
  final List<WordModel> learnedWords;
  final List<WordModel> wrongWords;
  final Function(String, String) onRename;
  final Function(String) onDelete;
  final Function(String) onExport;
  
  final Function(int)? onPointsEarned;

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
    this.onPointsEarned,
  });

  @override
  State<LibraryManagerScreen> createState() => _LibraryManagerScreenState();
}

class _LibraryManagerScreenState extends State<LibraryManagerScreen> {
  bool _isDownloading = false;
  String _lastSyncText = "Hiç senkronize edilmedi";

  @override
  void initState() {
    super.initState();
    _loadLastSyncInfo();
  }

  Future<void> _loadLastSyncInfo() async {
    final prefs = await SharedPreferences.getInstance();
    int lastSync = prefs.getInt('last_sync_time') ?? 0;
    if (lastSync > 0) {
      DateTime syncDate = DateTime.fromMillisecondsSinceEpoch(lastSync * 1000);
      Duration diff = DateTime.now().difference(syncDate);
      if (diff.inMinutes < 1) {
        setState(() => _lastSyncText = "Az önce senkronize edildi");
      } else if (diff.inHours < 1) {
        setState(() => _lastSyncText = "${diff.inMinutes} dakika önce senkronize edildi");
      } else if (diff.inDays < 1) {
        setState(() => _lastSyncText = "${diff.inHours} saat önce senkronize edildi");
      } else {
        setState(() => _lastSyncText = "${diff.inDays} gün önce senkronize edildi");
      }
    }
  }

  List<String> get _libraries {
    Set<String> libs = {};
    libs.addAll(widget.allWords.map((e) => e.libraryName));
    libs.addAll(widget.learnedWords.map((e) => e.libraryName));
    libs.addAll(widget.toRepeatWords.map((e) => e.libraryName));
    libs.addAll(widget.learningWords.map((e) => e.libraryName));
    libs.remove('Tekrarlanması Gerekenler'); 
    
    // YENİ: WordNet Veritabanını Listeye Ekle
    if (WordNetService().isLoaded) {
      libs.add('WordNet Veritabanı');
    }
    
    return libs.toList();
  }

  Widget _buildAnimatedItem(BuildContext context, int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index.clamp(0, 20) * 50)), 
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: child,
    );
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

  Future<void> _handleExport(String libName) async {
    Navigator.pop(context); 
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$libName dışa aktarılıyor, bekleyin..."), duration: const Duration(seconds: 2))
    );
    await widget.onExport(libName);
  }

  Future<void> _submitToCommunity(String libName) async {
    try {
      bool isMitosis = libName.startsWith('🧬'); 

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

      Set<String> uniqueSignatures = {};
      List<Map<String, dynamic>> jsonData = [];

      for (var w in wordsToExport) {
        String sig = isMitosis ? "${w.word}_${w.meanings.join('-')}" : w.word;
        
        if (!uniqueSignatures.contains(sig)) {
          uniqueSignatures.add(sig);
          jsonData.add({
            "word": w.word,
            "meanings": w.meanings,
            "examples": w.examples,
            "level": w.level,
            "libraryName": isMitosis ? libName : "Topluluk_Onerisi", 
          });
        }
      }

      String jsonString = json.encode(jsonData);
      final dir = await getTemporaryDirectory();
      
      String safeName = isMitosis ? "global_mitosis_submission" : "community_submission";
      final file = File('${dir.path}/${safeName}_${DateTime.now().millisecondsSinceEpoch}.json');
      
      await file.writeAsString(jsonString);

      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Dosya hazırlandı. E-posta uygulamanızı seçin."), backgroundColor: Colors.green)
        );
      }

      String subject = isMitosis ? "Yeni Global Mitoz Havuzu Önerisi 🧬" : "Yeni Topluluk Kütüphanesi Önerisi";
      String bodyText = isMitosis 
          ? "Merhaba Tayfun,\n\nEkte hazırladığım, quizlerimde bölünen %100 saf ve eşsiz kartlardan oluşan kütüphaneyi 'Global Mitoz Havuzu'na eklenmesi için gönderiyorum.\n\nHavuz Adı: $libName\nSaf Kart Sayısı: ${jsonData.length}"
          : "Merhaba Tayfun,\n\nEkte hazırladığım sözlük kütüphanesini 'Topluluk Kütüphanesi' havuzuna eklenmesi için gönderiyorum.\n\nKütüphane Adı: $libName\nKelime Sayısı: ${jsonData.length}";

      await Share.shareXFiles([XFile(file.path)], text: bodyText, subject: subject);
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _downloadLibrary(String targetUrl, String poolName) async {
    setState(() => _isDownloading = true);
    try {
      final response = await http.get(Uri.parse(targetUrl));

      if (response.statusCode == 200) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("İndirme başarılı! $poolName çözümleniyor..."), backgroundColor: Colors.blue));

        String content = utf8.decode(response.bodyBytes);
        
        final List<String> parsedJsons = await compute(parseLibraryDataInBackground, {
          'content': content, 
          'extension': 'json', 
          'libraryName': poolName, 
          'originalFileName': 'downloaded_pool.json'
        });
        
        if (parsedJsons.isNotEmpty && parsedJsons.first.contains('"error":')) {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(json.decode(parsedJsons.first)['error']), backgroundColor: Colors.red));
        } else {
           Set<String> existingSignatures = {
              ...widget.allWords.map((w) => "${w.word}_${w.meanings.join('-')}"),
              ...widget.learnedWords.map((w) => "${w.word}_${w.meanings.join('-')}"),
              ...widget.toRepeatWords.map((w) => "${w.word}_${w.meanings.join('-')}"),
              ...widget.learningWords.map((w) => "${w.word}_${w.meanings.join('-')}"),
           };

           List<WordModel> newWords = [];
           for (var jsonStr in parsedJsons) {
              try {
                var w = WordModel.fromJson(jsonStr)..listType = 'all';
                String sig = "${w.word}_${w.meanings.join('-')}";
                
                if (!existingSignatures.contains(sig)) {
                   newWords.add(w);
                   existingSignatures.add(sig); 
                }
              } catch(e) { continue; }
           }

           if (newWords.isNotEmpty) {
             await isar.writeTxn(() async { 
                await isar.wordModels.putAll(newWords); 
             });
             
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
                       Icon(poolName.contains("Mitoz") ? Icons.biotech : Icons.cloud_done, color: poolName.contains("Mitoz") ? Colors.purple : Colors.green, size: 70),
                       const SizedBox(height: 16),
                       const Text("Harika Haber!", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                       const SizedBox(height: 12),
                       Text("$poolName başarıyla yüklendi.\n\nSisteme tam ${newWords.length} adet benzersiz kelime/kart eklendi!", textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.4)),
                       const SizedBox(height: 24),
                       ElevatedButton(
                         style: ElevatedButton.styleFrom(backgroundColor: poolName.contains("Mitoz") ? Colors.purple : Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                         onPressed: () => Navigator.pop(ctx),
                         child: const Text("Mükemmel", style: TextStyle(fontWeight: FontWeight.bold))
                       )
                     ]
                   )
                 )
               );
             }
           } else {
             if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$poolName zaten güncel. Yeni eşsiz kart bulunamadı."), backgroundColor: Colors.orange));
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

  void _showLibrarySelectionForUpload() {
    var standardLibs = _libraries.where((l) => !l.startsWith('🧬') && l != 'İncelenecek Kelimeler' && l != 'WordNet Veritabanı').toList();
    if (standardLibs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gönderilecek standart kütüphane bulunamadı.")));
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1))
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.5), borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text("Hangi kütüphaneyi göndereceksiniz?", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: standardLibs.length,
                        itemBuilder: (ctx, i) => ListTile(
                          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.library_books, color: Colors.blue)),
                          title: Text(standardLibs[i], style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(context);
                            _executeCloudUpload(isMitosis: false, targetLibraryName: standardLibs[i]);
                          }
                        )
                      )
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUploadMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1))
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Wrap(
                  children: [
                    Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.5), borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Buluta Veri Gönder", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    ),
                    ListTile(
                      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.biotech, color: Colors.purple)),
                      title: const Text("🧬 Global Mitoz Havuzuna Gönder", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                      subtitle: const Text("En az 50 saf kart gerektirir (+50 TP ödüllü)", style: TextStyle(fontSize: 12)),
                      onTap: () { 
                        Navigator.pop(context); 
                        _executeCloudUpload(isMitosis: true); 
                      },
                    ),
                    ListTile(
                      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.public, color: Colors.blue)),
                      title: const Text("🌍 Standart Topluluk Havuzuna Gönder", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Belirli bir kütüphaneyi topluluğa gönderin", style: TextStyle(fontSize: 12)),
                      onTap: () { 
                        Navigator.pop(context); 
                        _showLibrarySelectionForUpload(); 
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _executeCloudUpload({required bool isMitosis, String? targetLibraryName}) async {
    if (isMitosis) {
      int count = widget.allWords.where((w) => w.libraryName.startsWith('🧬')).length +
                  widget.learningWords.where((w) => w.libraryName.startsWith('🧬')).length +
                  widget.toRepeatWords.where((w) => w.libraryName.startsWith('🧬')).length +
                  widget.learnedWords.where((w) => w.libraryName.startsWith('🧬')).length;
      if (count < 50) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30), SizedBox(width: 8), Text("Yetersiz Saf Kart", style: TextStyle(color: Colors.orange))]),
            content: Text("Global Mitoz Havuzuna katkıda bulunmak için en az 50 saf/mitoz kartınız olmalıdır!\n\nMevcut saf kart sayınız: $count\nLütfen quiz çözerek mitoz kart üretmeye devam edin.", style: const TextStyle(fontSize: 15, height: 1.4)),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Anladım", style: TextStyle(fontWeight: FontWeight.bold))
              )
            ],
          )
        );
        return; 
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 120,
              child: Lottie.network(
                'https://assets9.lottiefiles.com/packages/lf20_5tl1xxic.json', 
                errorBuilder: (context, error, stackTrace) => const CircularProgressIndicator(),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Güvenli Buluta Aktarılıyor...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text("Veriler senkronize ediliyor, lütfen bekleyin.", style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );

    var allLocalWords = [
      ...widget.allWords,
      ...widget.learningWords,
      ...widget.toRepeatWords,
      ...widget.learnedWords,
    ];

    Map<String, dynamic> result = await FirebaseSyncService.syncCardsToCloud(
      allLocalWords, 
      isMitosisPool: isMitosis,
      targetLibraryName: targetLibraryName
    );

    if (mounted) {
      Navigator.pop(context); 
      await _loadLastSyncInfo(); 

      bool success = result["success"] ?? false;
      int syncedCount = result["count"] ?? 0;
      String message = result["message"] ?? "İşlem tamamlandı.";

      if (success && syncedCount > 0) {
        if (widget.onPointsEarned != null) {
          widget.onPointsEarned!(50);
        }
        
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, color: Colors.green, size: 70),
                const SizedBox(height: 16),
                const Text("Tebrikler!", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.4)),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Harika", style: TextStyle(fontWeight: FontWeight.bold))
                )
              ]
            )
          )
        );
      } else if (success && syncedCount == 0) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(children: [Icon(Icons.info_outline, color: Colors.blue, size: 30), SizedBox(width: 8), Text("Zaten Güncel", style: TextStyle(color: Colors.blue))]),
            content: const Text("Tüm kartlarınız bulut ile zaten güncel.\n\nYeni bir kart üretilmediği için ek TP kazanılamadı.", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, height: 1.4)),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Anladım", style: TextStyle(fontWeight: FontWeight.bold))
              )
            ],
          )
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(children: [Icon(Icons.warning, color: Colors.orange), SizedBox(width: 8), Text("Uyarı")]),
            content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.4)),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Tamam")
              )
            ],
          )
        );
      }
    }
  }

  void _showDownloadMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1))
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Wrap(
                  children: [
                    Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.5), borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Buluttan Havuz İndir", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    ),
                    ListTile(
                      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.public, color: Colors.blue)),
                      title: const Text("🌍 Standart Topluluk Havuzu", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Kullanıcıların oluşturduğu karma listeler", style: TextStyle(fontSize: 12)),
                      onTap: () { 
                        Navigator.pop(context); 
                        _downloadLibrary('https://raw.githubusercontent.com/eldora25/Tayf-Sozluk-Pro/main/assets/user_recommended_library.json', 'Standart Topluluk Kütüphanesi'); 
                      },
                    ),
                    ListTile(
                      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.biotech, color: Colors.purple)),
                      title: const Text("🧬 Global Mitoz Havuzu", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                      subtitle: const Text("Sadece tek anlamlı, saf ve eşsiz bilgi kartları", style: TextStyle(fontSize: 12)),
                      onTap: () { 
                        Navigator.pop(context); 
                        _downloadLibrary('https://raw.githubusercontent.com/eldora25/Tayf-Sozluk-Pro/main/assets/global_mitosis_pool.json', 'Global Mitoz Havuzu'); 
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLibraryMenu(String libName) {
    // YENİ: WordNet menüsü için özel engelleme
    if (libName == 'WordNet Veritabanı') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [Icon(Icons.info_outline, color: Colors.indigo, size: 30), SizedBox(width: 8), Text("Sistem Kütüphanesi", style: TextStyle(color: Colors.indigo))]),
          content: const Text("WordNet Veritabanı (150.000+ Kelime) cihazı yormamak için ZIP dosyası üzerinden anlık olarak çalışır.\n\nBu sebeple bu kütüphaneyi yeniden adlandıramaz, dışa aktaramaz veya silemezsiniz.", style: TextStyle(fontSize: 15, height: 1.4)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Anladım", style: TextStyle(fontWeight: FontWeight.bold))
            )
          ],
        )
      );
      return;
    }

    bool isMitosis = libName.startsWith('🧬'); 

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1))
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Wrap(
                  children: [
                    Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.5), borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("'$libName' Seçenekleri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
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
                      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isMitosis ? Colors.purple.withOpacity(0.1) : Colors.deepPurple.withOpacity(0.1), shape: BoxShape.circle), child: Icon(isMitosis ? Icons.biotech : Icons.public, color: isMitosis ? Colors.purple : Colors.deepPurple)),
                      title: Text(isMitosis ? "Saf Kartları Topluluğa Gönder" : "Topluluğa Öner", style: TextStyle(fontWeight: FontWeight.bold, color: isMitosis ? Colors.purple : Colors.deepPurple)),
                      subtitle: Text(isMitosis ? "Bu saf havuzu Global Mitoza ekle" : "Bu kütüphaneyi ana havuza gönder", style: const TextStyle(fontSize: 12)),
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var libs = _libraries;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            expandedHeight: 140.0, 
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Kütüphaneler", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.cloud_sync, size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(_lastSyncText, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.normal)),
                    ],
                  ),
                ],
              ),
              centerTitle: false,
            ),
            actions: [
               Padding(
                 padding: const EdgeInsets.only(right: 8.0),
                 child: Container(
                   decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.2), shape: BoxShape.circle),
                   child: IconButton(
                    tooltip: "Buluta Senkronize Et (Gönder)",
                    icon: const Icon(Icons.cloud_upload_rounded, color: Colors.purpleAccent),
                    onPressed: _showUploadMenu,
                   ),
                 ),
               ),
               Padding(
                 padding: const EdgeInsets.only(right: 8.0),
                 child: Container(
                   decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                   child: IconButton(
                    tooltip: "Buluttan Havuz İndir",
                    icon: _isDownloading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.cloud_download, color: Colors.white),
                    onPressed: _isDownloading ? null : _showDownloadMenu, 
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
                      bool isMitosis = libName.startsWith('🧬'); 
                      
                      // YENİ: WordNet Veritabanı için devasa istatistik kartı görseli
                      if (libName == 'WordNet Veritabanı') {
                         int learned = widget.learnedWords.where((e) => e.libraryName == libName).length;
                         int wrong = widget.wrongWords.where((e) => e.libraryName == libName).fold(0, (a, b) => a + b.wrongCount);
                         double progress = 147306 > 0 ? (learned / 147306) : 0;

                         return _buildAnimatedItem(
                           context, 
                           index,
                           Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.08), 
                                borderRadius: BorderRadius.circular(20), 
                                border: Border.all(color: Colors.indigo.withOpacity(0.3), width: 2), 
                                boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]
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
                                                  const Icon(Icons.language, color: Colors.indigo, size: 28),
                                                  const SizedBox(width: 10),
                                                  const Expanded(child: Text("WordNet Veritabanı", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.indigo), overflow: TextOverflow.ellipsis)),
                                                ],
                                              ),
                                            ),
                                            Icon(Icons.more_vert, color: Colors.indigo.shade400),
                                          ],
                                        ),
                                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text("Toplam: 150.000+", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo)),
                                              const SizedBox(width: 16),
                                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text("Öğrenilen: $learned", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                                              const SizedBox(width: 16),
                                              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text("Yanlış: $wrong", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: Colors.indigo.withOpacity(0.1),
                                            color: Colors.indigoAccent,
                                            minHeight: 6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                         );
                      }

                      int total = widget.allWords.where((e) => e.libraryName == libName).length +
                                  widget.learnedWords.where((e) => e.libraryName == libName).length +
                                  widget.learningWords.where((e) => e.libraryName == libName).length +
                                  widget.toRepeatWords.where((e) => e.libraryName == libName).length;
                                  
                      int learned = widget.learnedWords.where((e) => e.libraryName == libName).length;
                      int wrong = widget.wrongWords.where((e) => e.libraryName == libName).fold(0, (a, b) => a + b.wrongCount);
                      
                      double progress = total > 0 ? (learned / total) : 0;

                      return _buildAnimatedItem(
                        context, 
                        index,
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isMitosis ? Colors.purpleAccent.withOpacity(0.05) : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: isMitosis ? Colors.purpleAccent.withOpacity(0.1) : Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                            border: Border.all(color: isMitosis ? Colors.purpleAccent.withOpacity(0.3) : Colors.grey.withOpacity(0.1), width: 1.5)
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
                                              Icon(isMitosis ? Icons.biotech : Icons.menu_book, color: isMitosis ? Colors.purpleAccent : Colors.deepPurple, size: 24),
                                              const SizedBox(width: 10),
                                              Expanded(child: Text(libName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isMitosis ? Colors.purpleAccent : Colors.deepPurple), overflow: TextOverflow.ellipsis)),
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
                                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text("Yanlış: $wrong", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: Colors.grey.withOpacity(0.2),
                                        color: isMitosis ? Colors.purpleAccent : Colors.greenAccent.shade400,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
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
