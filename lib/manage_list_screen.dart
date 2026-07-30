import 'package:flutter/material.dart';
import 'models.dart';

class ManageListScreen extends StatefulWidget {
  final String title;
  final List<WordModel> words;
  final bool showWrongCount;
  final bool showSrsLevel; 
  final Function(WordModel) onDelete;
  final Function(WordModel)? onLearned; 
  final Function() onClearAll;
  final Future<void> Function(WordModel)? onEdit; // YENİ: Düzenleme tetikleyicisi

  const ManageListScreen({
    super.key,
    required this.title,
    required this.words,
    this.showWrongCount = false,
    this.showSrsLevel = false,
    required this.onDelete,
    this.onLearned,
    required this.onClearAll,
    this.onEdit, // YENİ
  });

  @override
  State<ManageListScreen> createState() => _ManageListScreenState();
}

class _ManageListScreenState extends State<ManageListScreen> {
  String searchQuery = '';

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tümünü Sil", style: TextStyle(color: Colors.red)),
        content: const Text("Bu listedeki tüm kelimeleri çıkarmak istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              widget.onClearAll();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("TÜMÜNÜ ÇIKAR"),
          ),
        ],
      ),
    );
  }

  String _getSrsDayText(int level) {
    switch (level) {
      case 1: return "1. Gün";
      case 2: return "2. Gün";
      case 3: return "4. Gün"; 
      case 4: return "9. Gün";
      case 5: return "14. Gün";
      default: return "Beklemede";
    }
  }

  @override
  Widget build(BuildContext context) {
    var filteredList = widget.words.where((w) => 
      w.word.toLowerCase().contains(searchQuery.toLowerCase()) ||
      w.meanings.join(' ').toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            tooltip: 'Tümünü Çıkar',
            onPressed: widget.words.isNotEmpty ? _confirmClearAll : null,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Kelime veya Anlam Ara...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          Expanded(
            child: filteredList.isEmpty 
              ? const Center(child: Text("Bu liste şu an boş."))
              : ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    
                    return Dismissible(
                      key: Key('${item.id}_$index'), // ID üzerinden eşleştirme zırhı
                      direction: widget.onLearned != null 
                          ? DismissDirection.horizontal 
                          : DismissDirection.endToStart,
                      background: Container(
                        color: Colors.green,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.check_circle, color: Colors.white, size: 30),
                      ),
                      secondaryBackground: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white, size: 30),
                      ),
                      onDismissed: (direction) {
                        setState(() {
                          widget.words.remove(item);
                        });
                        if (direction == DismissDirection.endToStart) {
                          widget.onDelete(item);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kelime silindi."), duration: Duration(seconds: 1)));
                        } else if (direction == DismissDirection.startToEnd) {
                          if (widget.onLearned != null) widget.onLearned!(item);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kelime öğrenildi! ✅"), backgroundColor: Colors.green, duration: Duration(seconds: 1)));
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          title: Hero(
                            tag: 'hero_word_list_${item.id}',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(item.word, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple)),
                            ),
                          ),
                          subtitle: Text(item.meanings.join(', ')),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.showWrongCount)
                                Text("Yanlış: ${item.wrongCount}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              
                              if (widget.showSrsLevel && item.srsLevel > 0)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                  child: Text("${_getSrsDayText(item.srsLevel)} Tekrarı", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),

                              // YENİ: DÜZENLE BUTONU VE ASENKRON YENİLEME
                              if (widget.onEdit != null)
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                  tooltip: 'Düzenle',
                                  onPressed: () async {
                                    await widget.onEdit!(item);
                                    setState(() {}); // Düzenleme bitince listeyi yenile
                                  },
                                ),

                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                tooltip: 'Listeden Çıkar',
                                onPressed: () {
                                  widget.onDelete(item);
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
