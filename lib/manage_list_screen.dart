import 'package:flutter/material.dart';
import 'models.dart';

class ManageListScreen extends StatefulWidget {
  final String title;
  final List<WordModel> words;
  final bool showWrongCount;
  final Function(WordModel) onDelete;
  final Function() onClearAll;

  const ManageListScreen({
    super.key,
    required this.title,
    required this.words,
    this.showWrongCount = false,
    required this.onDelete,
    required this.onClearAll,
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
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text(item.word, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple)),
                        subtitle: Text(item.meanings.join(', ')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.showWrongCount)
                              Text("Yanlış: ${item.wrongCount}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
