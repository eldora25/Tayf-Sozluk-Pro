import 'dart:async'; 
import 'dart:math'; // EKLENDİ: min() fonksiyonu için matematik kütüphanesi
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart'; 
import 'models.dart';
import 'main.dart'; 

class ManageListScreen extends StatefulWidget {
  final String title;
  final List<WordModel> words;
  final bool showWrongCount;
  final bool showSrsLevel; 
  final Function(WordModel) onDelete;
  final Function(WordModel)? onLearned; 
  final Function() onClearAll;
  final Future<void> Function(WordModel)? onEdit;

  const ManageListScreen({
    super.key,
    required this.title,
    required this.words,
    this.showWrongCount = false,
    this.showSrsLevel = false,
    required this.onDelete,
    this.onLearned,
    required this.onClearAll,
    this.onEdit,
  });

  @override
  State<ManageListScreen> createState() => _ManageListScreenState();
}

class _ManageListScreenState extends State<ManageListScreen> {
  String searchQuery = '';
  Timer? _debounceTimer; 
  List<WordModel> _filteredList = [];

  @override
  void initState() {
    super.initState();
    _filteredList = widget.words;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); 
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          searchQuery = query;
          if (query.trim().isEmpty) {
            _filteredList = widget.words;
          } else {
            String lowerQuery = query.toLowerCase();
            _filteredList = widget.words.where((w) {
              return w.word.toLowerCase().contains(lowerQuery) || 
                     w.meanings.join(' ').toLowerCase().contains(lowerQuery);
            }).toList();
          }
        });
      }
    });
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Tümünü Sil", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("Bu listedeki tüm kelimeleri çıkarmak istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              widget.onClearAll();
              Navigator.pop(context);
              setState(() {
                _filteredList = widget.words;
              });
            },
            child: const Text("TÜMÜNÜ ÇIKAR", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _moveToReview(WordModel word) {
    HapticFeedback.heavyImpact();
    setState(() {
      word.libraryName = 'İncelenecek Kelimeler';
      word.listType = 'all';
      widget.words.remove(word);
      _filteredList.remove(word);
    });

    isar.writeTxnSync(() { isar.wordModels.putSync(word); });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("⚠️ Kelime incelenmek üzere ayrıldı!", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.orange)
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

  Widget _buildAnimatedItem(BuildContext context, int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      // GÜNCELLENDİ: min fonksiyonu için <int> tipi belirtildi ve math eklendi
      duration: Duration(milliseconds: 400 + (min<int>(index, 10) * 50)), 
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

  Widget _buildMitosisBadge(WordModel item) {
    final String dnaCode = "DNA-" + item.id.toString().padLeft(6, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: -0.5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white30, width: 1),
                  boxShadow: [
                    BoxShadow(color: Colors.orangeAccent.withOpacity(0.9), blurRadius: 12, spreadRadius: 2, offset: const Offset(-2, 0)),
                    BoxShadow(color: Colors.purpleAccent.withOpacity(0.9), blurRadius: 12, spreadRadius: 2, offset: const Offset(2, 0)),
                  ],
                ),
                child: Transform.rotate(
                  angle: 0.5, 
                  child: const Text(
                    "\u{1F9EC}", 
                    style: TextStyle(
                      fontSize: 12, 
                      shadows: [
                        Shadow(color: Colors.orangeAccent, blurRadius: 15),
                        Shadow(color: Colors.purpleAccent, blurRadius: 15),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.8), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fingerprint, color: Colors.purpleAccent, size: 10),
                  const SizedBox(width: 4),
                  Text(dnaCode, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrailingActions(WordModel item) {
    final String errorText = "Hata: " + item.wrongCount.toString();
    final String srsText = _getSrsDayText(item.srsLevel);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showWrongCount)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(errorText, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        
        if (widget.showSrsLevel && item.srsLevel > 0)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Text(srsText, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
  
        if (widget.onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueAccent),
            tooltip: 'Düzenle',
            onPressed: () async {
              final editCb = widget.onEdit;
              if (editCb != null) {
                await editCb(item);
                setState(() {
                  _filteredList = widget.words;
                });
              }
            },
          ),
  
        IconButton(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
          tooltip: 'İnceleneceklere Taşı',
          onPressed: () => _moveToReview(item),
        ),

        IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
          tooltip: 'Listeden Çıkar',
          onPressed: () {
            widget.onDelete(item);
            setState(() {
              _filteredList.remove(item);
            });
          },
        ),
      ],
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    final WordModel item = _filteredList[index];
    final bool isMitosis = item.libraryName.startsWith('\u{1F9EC}');
    final String dismissKey = '${item.id}_$index';
    final String heroTag = 'hero_word_list_${item.word}_$index';

    return RepaintBoundary(
      child: _buildAnimatedItem(
        context, 
        index,
        Dismissible(
          key: Key(dismissKey),
          direction: widget.onLearned != null ? DismissDirection.horizontal : DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.check_circle, color: Colors.white, size: 30),
          ),
          secondaryBackground: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white, size: 30),
          ),
          onDismissed: (direction) {
            setState(() {
              widget.words.remove(item);
              _filteredList.remove(item);
            });
            if (direction == DismissDirection.endToStart) {
              widget.onDelete(item);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kelime silindi."), duration: Duration(seconds: 1)));
            } else if (direction == DismissDirection.startToEnd) {
              final learnCb = widget.onLearned;
              if (learnCb != null) {
                learnCb(item);
              }
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kelime öğrenildi! ✅"), backgroundColor: Colors.green, duration: Duration(seconds: 1)));
            }
          },
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isMitosis ? BorderSide(color: Colors.purpleAccent.withOpacity(0.3), width: 1.5) : BorderSide.none,
            ),
            color: isMitosis ? Colors.purpleAccent.withOpacity(0.05) : Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                title: Hero(
                  tag: heroTag,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Text(item.word, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isMitosis ? Colors.purpleAccent : Colors.deepPurple)),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(item.meanings.join(', '), style: const TextStyle(fontWeight: FontWeight.w500)),
                    if (isMitosis) _buildMitosisBadge(item),
                  ],
                ),
                trailing: _buildTrailingActions(item),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (searchQuery.isEmpty && _filteredList.length != widget.words.length) {
      _filteredList = widget.words;
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            expandedHeight: 110.0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              centerTitle: false,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                tooltip: 'Tümünü Çıkar',
                onPressed: widget.words.isNotEmpty ? _confirmClearAll : null,
              )
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: "Kelime veya Anlam Ara...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Theme.of(context).primaryColor.withOpacity(0.05),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ),
          _filteredList.isEmpty 
            ? const SliverFillRemaining(
                child: Center(child: Text("Bu liste şu an boş.", style: TextStyle(fontSize: 16, color: Colors.grey))),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  _buildListItem,
                  childCount: _filteredList.length,
                ),
              ),
        ],
      ),
    );
  }
}
