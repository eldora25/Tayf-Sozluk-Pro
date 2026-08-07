import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'core/db_helper.dart'; 
import 'firebase_sync_service.dart';

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

  void _showMergeDialog(String initialLib) {
    List<String> selectedLibs = [initialLib];
    TextEditingController nameCtrl = TextEditingController(text: "Birlestirilmis01");
    List<String> mergeableLibs = _libraries.where((l) => l != 'WordNet Veritabanı').toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.merge_type, color: Colors.teal),
                SizedBox(width: 8),
                Text("Kütüphaneleri Birleştir", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Hedef Kütüphane Adı:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl, 
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true, fillColor: Colors.grey.withOpacity(0.1)
                    )
                  ),
                  const SizedBox(height: 16),
                  const Text("Birleştirilecek Kütüphaneler:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: mergeableLibs.map((lib) {
                          return CheckboxListTile(
                            title: Text(lib, style: const TextStyle(fontSize: 14)),
                            value: selectedLibs.contains(lib),
                            activeColor: Colors.teal,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) selectedLibs.add(lib);
                                else selectedLibs.remove(lib);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  )
                ],
              )
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || selectedLibs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Geçerli bir isim girin ve en az bir kütüphane seçin!")));
                    return;
                  }
                  Navigator.pop(ctx);
                  await _executeMerge(selectedLibs, nameCtrl.text.trim());
                },
                child: const Text("BİRLEŞTİR", style: TextStyle(fontWeight: FontWeight.bold))
              )
            ]
          );
        }
      )
    );
  }

  Future<void> _executeMerge(List<String> libsToMerge, String newName) async {
    setState(() {
      for (var w in widget.allWords) { if (libsToMerge.contains(w.libraryName)) w.libraryName = newName; }
      for (var w in widget.learnedWords) { if (libsToMerge.contains(w.libraryName)) w.libraryName = newName; }
      for (var w in widget.toRepeatWords) { if (libsToMerge.contains(w.libraryName)) w.libraryName = newName; }
      for (var w in widget.learningWords) { if (libsToMerge.contains(w.libraryName)) w.libraryName = newName; }
      for (var w in widget.wrongWords) { if (libsToMerge.contains(w.libraryName)) w.libraryName = newName; }
    });
    
    await isar.writeTxn(() async {
      for (String lib in libsToMerge) {
        // DÜZELTİLDİ: Isar 3.x sürümünde findAll() hatasını önlemek için where() veya filter().build() yapısı kullanıldı
        List<WordModel> toUpdate = await isar.wordModels.filter().libraryNameEqualTo(lib).findAll();
        for (var w in toUpdate) { w.libraryName = newName; }
        await isar.wordModels.putAll(toUpdate);
      }
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${libsToMerge.length} adet kütüphane başarıyla '$newName' olarak birleştirildi."), backgroundColor: Colors.teal)
      );
      setState(() {});
    }
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

  @override
  Widget build(BuildContext context) {
    var libs = _libraries;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kütüphane Yönetimi", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: libs.isEmpty
          ? const Center(child: Text("Kayıtlı kütüphane bulunamadı."))
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: libs.length,
              itemBuilder: (context, index) {
                String libName = libs[index];
                
                int total = widget.allWords.where((e) => e.libraryName == libName).length +
                            widget.learnedWords.where((e) => e.libraryName == libName).length +
                            widget.learningWords.where((e) => e.libraryName == libName).length +
                            widget.toRepeatWords.where((e) => e.libraryName == libName).length;
                            
                int learned = widget.learnedWords.where((e) => e.libraryName == libName).length;

                return _buildAnimatedItem(
                  context,
                  index,
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(libName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text("Toplam: $total kelime | Öğrenilen: $learned", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'merge') {
                            _showMergeDialog(libName);
                          } else if (value == 'rename') {
                            _showEditDialog(libName);
                          } else if (value == 'export') {
                            _handleExport(libName);
                          } else if (value == 'delete') {
                            _showDeleteConfirm(libName);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'merge', child: Row(children: [Icon(Icons.merge_type, color: Colors.teal, size: 20), SizedBox(width: 8), Text("Kütüphaneleri Birleştir")])),
                          const PopupMenuItem(value: 'rename', child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 20), SizedBox(width: 8), Text("Adını Değiştir")])),
                          const PopupMenuItem(value: 'export', child: Row(children: [Icon(Icons.share, color: Colors.green, size: 20), SizedBox(width: 8), Text("Dışa Aktar / Paylaş")])),
                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text("Kütüphaneyi Sil")])),
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
