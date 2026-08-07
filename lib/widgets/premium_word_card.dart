import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models.dart';

class PremiumWordCard extends StatelessWidget {
  final WordModel word;
  final bool isFront;
  final Animation<double> glowAnimation;
  final VoidCallback onSpeak;
  final VoidCallback onEdit;

  const PremiumWordCard({
    super.key,
    required this.word,
    required this.isFront,
    required this.glowAnimation,
    required this.onSpeak,
    required this.onEdit,
  });

  final List<Color> distinctColors = const [
    Color(0xFFFFEA00), Color(0xFFD500F9), Color(0xFF00E5FF), Color(0xFFFF3D00), Color(0xFF00E676)
  ];

  Widget _buildCrown(int level, bool isMitosis) {
    if (level == 0) return const SizedBox.shrink();
    List<Widget> pieces = [];
    if (level == 1) {
      pieces = [const Icon(Icons.change_history, size: 16, color: Color(0xFFFFEA00))]; 
    } else if (level == 2) {
      pieces = [
        const Icon(Icons.spa, size: 14, color: Color(0xFFD500F9)),
        const Icon(Icons.keyboard_arrow_up, size: 20, color: Color(0xFFD500F9)),
        const Icon(Icons.spa, size: 14, color: Color(0xFFD500F9)),
      ];
    } else if (level == 3) {
      pieces = [
        const Icon(Icons.filter_vintage, size: 14, color: Color(0xFF00E5FF)),
        const Icon(Icons.spa, size: 18, color: Color(0xFF00E5FF)),
        const Icon(Icons.workspace_premium, size: 24, color: Color(0xFF00E5FF)),
        const Icon(Icons.spa, size: 18, color: Color(0xFF00E5FF)),
        const Icon(Icons.filter_vintage, size: 14, color: Color(0xFF00E5FF)),
      ];
    } else if (level == 4) {
      pieces = [
        const Icon(Icons.ac_unit, size: 14, color: Color(0xFFFF3D00)),
        const Icon(Icons.filter_vintage, size: 18, color: Color(0xFFFF3D00)),
        const Icon(Icons.spa, size: 22, color: Color(0xFFFF3D00)),
        const Icon(Icons.military_tech, size: 28, color: Color(0xFFFF3D00)),
        const Icon(Icons.spa, size: 22, color: Color(0xFFFF3D00)),
        const Icon(Icons.filter_vintage, size: 18, color: Color(0xFFFF3D00)),
        const Icon(Icons.ac_unit, size: 14, color: Color(0xFFFF3D00)),
      ];
    } else if (level == 5) {
      pieces = [
        const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF00E676)),
        const Icon(Icons.ac_unit, size: 18, color: Color(0xFF00E676)),
        const Icon(Icons.filter_vintage, size: 22, color: Color(0xFF00E676)),
        const Icon(Icons.spa, size: 26, color: Color(0xFF00E676)),
        const Icon(Icons.diamond, size: 32, color: Colors.white),
        const Icon(Icons.spa, size: 26, color: Color(0xFF00E676)),
        const Icon(Icons.filter_vintage, size: 22, color: Color(0xFF00E676)),
        const Icon(Icons.ac_unit, size: 18, color: Color(0xFF00E676)),
        const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF00E676)),
      ];
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: pieces);
  }

  BoxDecoration _getPremiumCardDecoration(BuildContext context, bool isDark, bool isMitosis) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: isDark 
            ? [isMitosis ? Colors.purpleAccent.shade400.withOpacity(0.15) : Theme.of(context).cardColor, Theme.of(context).cardColor.withOpacity(0.8)]
            : [isMitosis ? Colors.purpleAccent.shade100.withOpacity(0.1) : Colors.white, Theme.of(context).scaffoldBackgroundColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: isMitosis ? Colors.purpleAccent.withOpacity(0.4) : Theme.of(context).primaryColor.withOpacity(0.3), width: 1.5),
      boxShadow: [BoxShadow(color: isMitosis ? Colors.purpleAccent.withOpacity(0.1) : Theme.of(context).primaryColor.withOpacity(0.15), blurRadius: 25, offset: const Offset(0, 10))]
    );
  }

  Color _getTextColor(BuildContext context, bool isDark, bool isMitosis) {
    if (isMitosis) return isDark ? Colors.white : Colors.purple.shade900;
    return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  }

  Widget _buildTopBadge(int level, bool isMitosis, bool isWordNet, String pos) {
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.symmetric(vertical: 8), 
      decoration: BoxDecoration(
        color: isWordNet ? Colors.indigo.withOpacity(0.15) : (isMitosis ? Colors.purpleAccent.withOpacity(0.15) : (level > 0 ? distinctColors[level - 1].withOpacity(0.15) : Colors.blueGrey.withOpacity(0.15))), 
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22)),
        border: Border(bottom: BorderSide(color: isWordNet ? Colors.indigo.withOpacity(0.5) : (isMitosis ? Colors.purpleAccent.withOpacity(0.5) : (level > 0 ? distinctColors[level - 1].withOpacity(0.5) : Colors.blueGrey.withOpacity(0.5))), width: 2))
      ), 
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (level > 0 && !isWordNet) _buildCrown(level, isMitosis), 
          if (level > 0 && !isWordNet) const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isWordNet) ...[
                const Icon(Icons.language, size: 16, color: Colors.indigo),
                const SizedBox(width: 8),
                Text("WORDNET SÖZLÜK ${pos.isNotEmpty ? '[${pos.toUpperCase()}]' : ''}", style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
              ] else if (isMitosis) ...[
                const Icon(Icons.biotech, size: 16, color: Colors.purpleAccent),
                const SizedBox(width: 8),
                Text(level > 0 ? "MİTOZ (SAF KART) • SRS: $level/5" : "YENİ MİTOZ (SAF KART)", style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
              ] else ...[
                Icon(Icons.menu_book, size: 16, color: level > 0 ? distinctColors[level - 1] : Colors.blueGrey),
                const SizedBox(width: 8),
                Text(level > 0 ? "STANDART KART • SRS: $level/5" : "YENİ STANDART KART", style: TextStyle(color: level > 0 ? distinctColors[level - 1] : Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
              ]
            ],
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    int level = word.srsLevel.clamp(0, 5);
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isMitosis = word.libraryName.startsWith('\u{1F9EC}'); 
    bool isWordNet = word.libraryName == 'WordNet Veritabanı';

    String displayWord = word.word;
    if (RegExp(r'^\d{8}-').hasMatch(displayWord) || displayWord.contains('[ID:')) {
        displayWord = word.synonyms.isNotEmpty ? word.synonyms.first : "WordNet Terimi";
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: glowAnimation,
        builder: (context, child) {
          Widget cardContent = Container(
            width: 290, height: 320, 
            decoration: _getPremiumCardDecoration(context, isDark, isMitosis), 
            child: Column(
              children: [
                _buildTopBadge(level, isMitosis, isWordNet, word.pos),
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(bottom: 80, top: isFront ? 40 : 24, left: 20, right: 20),
                        child: isFront 
                          ? Center(child: Hero(tag: 'hero_word_${word.word}', child: Material(type: MaterialType.transparency, child: Text(displayWord, textAlign: TextAlign.center, style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: _getTextColor(context, isDark, isMitosis))))))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(child: Text(displayWord, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _getTextColor(context, isDark, isMitosis)))), 
                                Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Divider(color: _getTextColor(context, isDark, isMitosis).withOpacity(0.3))), 
                                if (isWordNet) ...[
                                  Row(children: [const Icon(Icons.menu_book, size: 14, color: Colors.indigo), const SizedBox(width: 6), Text("Definition:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.indigo.shade300))]),
                                  ...word.meanings.map((m) => Padding(padding: const EdgeInsets.only(top: 4.0, bottom: 8.0, left: 6), child: Text(m, style: TextStyle(fontSize: 15, height: 1.4, fontWeight: FontWeight.w600, color: _getTextColor(context, isDark, isMitosis))))),
                                  if (word.synonyms.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(children: [const Icon(Icons.link, size: 14, color: Colors.teal), const SizedBox(width: 6), Text("Synonyms:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.teal.shade300))]),
                                    Padding(padding: const EdgeInsets.only(top: 4.0, left: 6), child: Wrap(spacing: 6, runSpacing: 6, children: word.synonyms.take(6).map((s) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.teal.withOpacity(0.3))), child: Text(s, style: const TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold)))).toList())),
                                    const SizedBox(height: 8),
                                  ],
                                  if (word.examples.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(children: [const Icon(Icons.format_quote, size: 14, color: Colors.orange), const SizedBox(width: 6), Text("Examples:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.orange.shade300))]),
                                    ...word.examples.map((e) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6.0, left: 8.0),
                                      child: Text("» $e", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14, height: 1.4)),
                                    )),
                                  ]
                                ] else ...[
                                  ...word.meanings.map((m) => Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Text("• $m", style: TextStyle(fontSize: 17, height: 1.4, fontWeight: FontWeight.w600, color: _getTextColor(context, isDark, isMitosis))))),
                                  if (word.examples.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Text("Örnekler:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isMitosis ? Colors.pinkAccent : Theme.of(context).colorScheme.secondary)),
                                    const SizedBox(height: 6),
                                    ...word.examples.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text("» $e", style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, height: 1.4, color: _getTextColor(context, isDark, isMitosis))))),
                                  ]
                                ]
                              ]
                            ),
                      ),
                      Positioned(right: 5, top: 5, child: IconButton(icon: Icon(Icons.volume_up, size: 30, color: _getTextColor(context, isDark, isMitosis).withOpacity(0.7)), onPressed: onSpeak)), 
                      Positioned(left: 5, top: 5, child: IconButton(icon: Icon(Icons.settings, size: 28, color: _getTextColor(context, isDark, isMitosis).withOpacity(0.5)), onPressed: onEdit)),
                      
                      if (isMitosis && !isWordNet)
                        Positioned(
                          bottom: 15, left: 0, right: 0,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle, color: Colors.black, border: Border.all(color: Colors.yellowAccent.shade700, width: 2),
                                    boxShadow: [BoxShadow(color: Colors.yellowAccent.withOpacity(0.5), blurRadius: 8)]
                                  ),
                                  child: ClipOval(child: Image.asset('assets/acd21dcc2efa6d403b570d2bcaa10ef5.jpg', fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.coronavirus, color: Colors.yellowAccent, size: 24))),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purpleAccent.withOpacity(0.8), width: 1), boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(0.5), blurRadius: 8)]),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.fingerprint, color: Colors.purpleAccent, size: 14),
                                      const SizedBox(width: 6),
                                      Text("DNA-${word.id.toString().padLeft(6, '0')}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ]
                  )
                )
              ],
            ),
          );

          Widget current = cardContent;
          if (level > 0 && !isWordNet) {
            for (int i = 0; i < level; i++) {
              double thickness = 2.0 + (i * 1.5); 
              current = Container(
                padding: EdgeInsets.all(thickness), 
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24 + ((i + 1) * thickness)),
                  border: Border.all(color: Colors.black.withOpacity(0.2), width: 1.0 + (i * 0.5)), 
                  gradient: LinearGradient(colors: [distinctColors[i].withOpacity(0.9), distinctColors[i]], begin: isFront ? Alignment.topLeft : Alignment.bottomRight, end: isFront ? Alignment.bottomRight : Alignment.topLeft),
                  boxShadow: (i == level - 1) ? [BoxShadow(color: distinctColors[i].withOpacity((0.6 * glowAnimation.value).clamp(0.0, 1.0)), blurRadius: 25 * glowAnimation.value, spreadRadius: 6 * glowAnimation.value)] : const [],
                ),
                child: current,
              );
            }
          } else {
             current = Container(
               padding: const EdgeInsets.all(3),
               decoration: BoxDecoration(
                 color: isWordNet ? Colors.indigo : (isMitosis ? Colors.purpleAccent : (isFront ? Theme.of(context).primaryColor : Colors.green)),
                 borderRadius: BorderRadius.circular(26), 
                 boxShadow: [BoxShadow(color: isWordNet ? Colors.indigo.withOpacity(0.4) : (isMitosis ? Colors.purpleAccent.withOpacity(0.4) : Theme.of(context).primaryColor.withOpacity(0.4)), blurRadius: 15, offset: const Offset(0, 5))]
               ),
               child: current,
             );
          }
          return current;
        }
      ),
    );
  }
}
