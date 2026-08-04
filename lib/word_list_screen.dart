import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'main.dart'; 

class WordListScreen extends StatefulWidget {
  final List<WordModel> words;
  final Function(WordModel) onDelete;
  final Function(WordModel)? onLearned; 

  const WordListScreen({super.key, required this.words, required this.onDelete, this.onLearned});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  String searchQuery = '';
  List<WordModel> _filteredList = [];
  Timer? _debounceTimer; 

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
    
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          searchQuery = query;
          if (query.trim().isEmpty) {
            _filteredList = widget.words;
          } else {
            String lowerQuery = query.toLowerCase().trim();
            
            // DÜZELTİLDİ: Sadece kelimenin kendisinde ve baştan başlayanları bulur. Anlamlarda arama yapmaz.
            _filteredList = widget.words.where((w) {
              return w.word.toLowerCase().startsWith(lowerQuery);
            }).toList();

            // ZEKİ SIRALAMA: Önce tam eşleşen (cat), sonra uzayanlar (caterpillar).
            _filteredList.sort((a, b) {
              String aWord = a.word.toLowerCase();
              String bWord = b.word.toLowerCase();
              if (aWord == lowerQuery && bWord != lowerQuery) return -1;
              if (bWord == lowerQuery && aWord != lowerQuery) return 1;
              return aWord.compareTo(bWord);
            });
          }
        });
      }
    });
  }

  Widget _buildAnimatedItem(BuildContext context, int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index.clamp(0, 10) * 50)), 
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

  Widget _buildMitosisBadge(WordModel item) {
    final String dnaCode = "DNA-" + item.id.toString().padLeft(6, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Wrap( // DÜZELTİLDİ: Taşmayı önlemek için Row yerine Wrap kullanıldı
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
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

  Widget _buildExpansionContent(WordModel item) {
    List<Widget> contentList = [];
    contentList.add(const Text("Anlamlar:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)));
    
    for (var m in item.meanings) {
      contentList.add(Text("• " + m, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4)));
    }
    
    if (item.examples.isNotEmpty) {
      contentList.add(const SizedBox(height: 8));
      contentList.add(const Text("Örnekler:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)));
      for (var e in item.examples) {
        contentList.add(Text("» " + e, style: const TextStyle(fontStyle: FontStyle.italic, height: 1.4)));
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: contentList,
      ),
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    final WordModel item = _filteredList[index];
    final bool isMitosis = item.libraryName.startsWith('\u{1F9EC}');
    final String dismissKey = '${item.id}_$index';
    final String heroTag = 'hero_word_${item.word}_$index';
    final String subtitleText = item.libraryName + " / " + item.level;

    return RepaintBoundary(
      child: _buildAnimatedItem(
        context, 
        index,
        Dismissible(
          key: Key(dismissKey),
          direction: widget.onLearned != null ? DismissDirection.horizontal : DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.check_circle, color: Colors.white, size: 30),
          ),
          secondaryBackground: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
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
            } else if (direction == DismissDirection.startToEnd) {
              final learnCb = widget.onLearned;
              if (learnCb != null) {
                learnCb(item);
              }
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
            child: ExpansionTile(
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
                  Text(subtitleText),
                  if (isMitosis) _buildMitosisBadge(item),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    tooltip: 'İnceleneceklere Taşı',
                    onPressed: () => _moveToReview(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      widget.onDelete(item);
                      setState(() {
                        _filteredList.remove(item);
                      });
                    },
                  ),
                ],
              ),
              children: [
                _buildExpansionContent(item),
              ],
            ),
          ),
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasWordNet = widget.words.any((w) => w.libraryName == 'WordNet Veritabanı');

    // DÜZELTİLDİ: Build içinde re-filtering yapılarak debounce bozuluyordu. Sadece boşken ana listeyi çeker.
    if (searchQuery.isEmpty && _filteredList.length != widget.words.length) {
      _filteredList = widget.words;
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            expandedHeight: 110.0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text("Kelime Listesi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              centerTitle: false,
            ),
          ),
          
          if (hasWordNet)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(12), 
                  border: Border.all(color: Colors.indigo.withOpacity(0.5))
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.indigo),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text("WordNet veritabanından cihazı yormamak için rastgele 200 kelimelik bir havuz gösterilmektedir. Tamamı WordNet Browser'dan aranabilir.", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12))
                    )
                  ]
                )
              )
            ),
            
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: "İngilizce Kelime Ara (Örn: cat)...",
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
                  child: Center(child: Text("Sonuç bulunamadı.", style: TextStyle(fontSize: 16, color: Colors.grey))),
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
