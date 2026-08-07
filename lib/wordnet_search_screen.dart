import 'dart:ui';
import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'models.dart';
import 'main.dart';
import 'core/db_helper.dart';

class WordNetSearchScreen extends StatefulWidget {
  final List<WordModel> words;
  const WordNetSearchScreen({super.key, required this.words});

  @override
  State<WordNetSearchScreen> createState() => _WordNetSearchScreenState();
}

class _WordNetSearchScreenState extends State<WordNetSearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<WordModel> _searchResults = [];
  bool _isLoading = false;
  late AnimationController _fadeController;
  Timer? _debounceTimer; 

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); 
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _executeSearch(query);
    });
  }

  void _executeSearch(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    String lowerQuery = query.toLowerCase().trim();

    try {
      // DÜZELTİLDİ: wordContains yerine wordStartsWith kullanıldı.
      // Sadece kelimenin kendisinde ve en baştan itibaren arama yapar (Çok daha hızlıdır)
      List<WordModel> results = await isar.wordModels
          .filter()
          .libraryNameEqualTo('WordNet Veritabanı')
          .and()
          .wordStartsWith(lowerQuery, caseSensitive: false)
          .limit(50)
          .findAll();

      // ZEKİ SIRALAMA: Önce "cat" gibi birebir eşleşenleri öne alır, sonra "caterpillar" gibi uzayanları dizer.
      results.sort((a, b) {
        String aWord = a.word.toLowerCase();
        String bWord = b.word.toLowerCase();
        if (aWord == lowerQuery && bWord != lowerQuery) return -1;
        if (bWord == lowerQuery && aWord != lowerQuery) return 1;
        return aWord.compareTo(bWord);
      });

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index.clamp(0, 15) * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildTag(String text, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("WordNet Browser", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor.withOpacity(0.7), Theme.of(context).colorScheme.secondary.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).primaryColor.withOpacity(0.05), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: "İngilizce kelime ara (Örn: run)...",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Icon(Icons.travel_explore, color: Theme.of(context).primaryColor, size: 28),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            _searchController.clear();
                            _executeSearch('');
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                      onChanged: _onSearchChanged, 
                    ),
                  ),
                ),
              ),
            ),
            
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_searchResults.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.manage_search, size: 80, color: Theme.of(context).primaryColor.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty ? "150.000+ Kelime Arasında Gezin" : "Sonuç bulunamadı.",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      WordModel item = _searchResults[index];
                      return _buildAnimatedItem(
                        index,
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.2), width: 1.5),
                          ),
                          color: isDark ? Colors.grey.shade900 : Colors.white,
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            title: Text(
                              item.word,
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Theme.of(context).primaryColor),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  if (item.pos.isNotEmpty)
                                    _buildTag(item.pos.toUpperCase(), Colors.purple, Icons.account_tree),
                                  _buildTag("WordNet", Colors.blue, Icons.language),
                                ],
                              ),
                            ),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.03),
                                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [Icon(Icons.menu_book, size: 16, color: Theme.of(context).primaryColor), const SizedBox(width: 8), Text("Tanım (Definition):", style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor))]),
                                    const SizedBox(height: 8),
                                    ...item.meanings.map((m) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                                      child: Text("• $m", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, height: 1.4)),
                                    )),
                                    
                                    if (item.synonyms.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Row(children: [const Icon(Icons.link, size: 16, color: Colors.teal), const SizedBox(width: 8), Text("Eş Anlamlılar (Synonyms):", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.teal.shade400))]),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8, runSpacing: 8,
                                        children: item.synonyms.map((s) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.teal.withOpacity(0.3))),
                                          child: Text(s, style: const TextStyle(fontSize: 13, color: Colors.teal, fontWeight: FontWeight.bold)),
                                        )).toList(),
                                      ),
                                    ],
                                    
                                    if (item.antonyms.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Row(children: [const Icon(Icons.link_off, size: 16, color: Colors.redAccent), const SizedBox(width: 8), Text("Zıt Anlamlılar (Antonyms):", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent.shade400))]),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8, runSpacing: 8,
                                        children: item.antonyms.map((a) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                                          child: Text(a, style: const TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                        )).toList(),
                                      ),
                                    ],

                                    if (item.examples.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Row(children: [const Icon(Icons.format_quote, size: 16, color: Colors.orange), const SizedBox(width: 8), Text("Örnekler (Examples):", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.orange.shade400))]),
                                      const SizedBox(height: 8),
                                      ...item.examples.map((e) => Padding(
                                        padding: const EdgeInsets.only(bottom: 6.0, left: 8.0),
                                        child: Text("» $e", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14, height: 1.4)),
                                      )),
                                    ]
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _searchResults.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
