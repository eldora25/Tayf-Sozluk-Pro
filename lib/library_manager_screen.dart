import 'package:flutter/material.dart';
import 'models.dart';

class LibraryManagerScreen extends StatefulWidget {
  final List<WordModel> allWords;
  final List<WordModel> learnedWords;
  final List<WordModel> wrongWords;
  final Function(String, String) onRename;
  final Function(String) onDelete;
  final Function(String) onExport;

  const LibraryManagerScreen({
    super.key,
    required this.allWords,
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
  List<String> get _libraries {
    Set<String> libs = {};
    libs.addAll(widget.allWords.map((e) => e.libraryName));
    libs.addAll(widget.learnedWords.map((e) => e.libraryName));
    libs.remove('Tekrarlanması Gerekenler'); // Sanal kütüphaneyi gizle
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
      appBar: AppBar(title: const Text("Kütüphane Yönetimi")),
      body: libs.isEmpty
          ? const Center(child: Text("Kayıtlı kütüphane bulunamadı."))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: libs.length,
              itemBuilder: (context, index) {
                String libName = libs[index];
                int total = widget.allWords.where((e) => e.libraryName == libName).length +
                            widget.learnedWords.where((e) => e.libraryName == libName).length;
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Toplam: $total", style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text("Öğrenilen: $learned", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              Text("Yanlış: $wrong", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
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
