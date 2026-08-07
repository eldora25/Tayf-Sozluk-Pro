import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'models.dart';
import 'core/db_helper.dart';
import 'core/tts_manager.dart'; 

enum EditAction { update, delete, copy, move }

class EditWordScreen extends StatefulWidget {
  final WordModel word;
  final List<String> availableLibraries;
  final Function(EditAction, WordModel) onAction;

  const EditWordScreen({
    super.key,
    required this.word,
    required this.availableLibraries,
    required this.onAction,
  });

  @override
  State<EditWordScreen> createState() => _EditWordScreenState();
}

class _EditWordScreenState extends State<EditWordScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _wordText;
  late String _level;
  late String _library;
  late List<String> _currentLibraries;
  
  late List<TextEditingController> _meaningControllers;
  late List<TextEditingController> _exampleControllers;

  @override
  void initState() {
    super.initState();
    _wordText = widget.word.word;
    
    _currentLibraries = widget.availableLibraries
        .where((lib) => lib != 'Tekrarlanması Gerekenler')
        .toSet()
        .toList();
        
    if (!_currentLibraries.contains('+ Yeni Kütüphane Oluştur')) {
      _currentLibraries.add('+ Yeni Kütüphane Oluştur');
    }

    _library = widget.word.libraryName;
    if (!_currentLibraries.contains(_library) && _currentLibraries.isNotEmpty) {
      _library = _currentLibraries.first;
    }
    
    _level = widget.word.level;
    List<String> validLevels = ['A1','A2','B1','B2','C1','C2','Genel'];
    if (!validLevels.contains(_level)) {
      _level = 'Genel'; 
    }

    _meaningControllers = widget.word.meanings.isNotEmpty 
        ? widget.word.meanings.map((m) => TextEditingController(text: m)).toList()
        : [TextEditingController()];
        
    _exampleControllers = widget.word.examples.isNotEmpty
        ? widget.word.examples.map((e) => TextEditingController(text: e)).toList()
        : [TextEditingController()];
  }

  @override
  void dispose() {
    for (var c in _meaningControllers) { c.dispose(); }
    for (var c in _exampleControllers) { c.dispose(); }
    super.dispose();
  }

  Future<void> _showNewLibraryDialog() async {
    TextEditingController newLibCtrl = TextEditingController();
    String? newLibName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Yeni Kütüphane", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: newLibCtrl,
          decoration: InputDecoration(
            hintText: "Kütüphane adını girin", 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Theme.of(context).primaryColor.withOpacity(0.05),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (newLibCtrl.text.trim().isNotEmpty) {
                Navigator.pop(context, newLibCtrl.text.trim());
              }
            }, 
            child: const Text("Oluştur", style: TextStyle(fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (newLibName != null && newLibName.isNotEmpty) {
      setState(() {
        if (!_currentLibraries.contains(newLibName)) {
          _currentLibraries.insert(_currentLibraries.length - 1, newLibName);
        }
        _library = newLibName;
      });
    } else {
      setState(() {
        if (!_currentLibraries.contains(_library)) {
          _library = _currentLibraries.first;
        }
      });
    }
  }

  InputDecoration _buildInputDeco(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      prefixIcon: icon != null ? Icon(icon, color: Theme.of(context).primaryColor) : null,
      filled: true,
      fillColor: Theme.of(context).cardColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2)),
    );
  }

  WordModel _getUpdatedWord() {
    return WordModel(
      word: _wordText.trim(),
      meanings: _meaningControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
      examples: _exampleControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
      level: _level,
      libraryName: _library,
      correctCount: widget.word.correctCount,
      wrongCount: widget.word.wrongCount,
      listType: widget.word.listType,
      srsLevel: widget.word.srsLevel,
      nextReviewDate: widget.word.nextReviewDate,
      sourceLanguage: widget.word.sourceLanguage,
      targetLanguage: widget.word.targetLanguage,
      pos: widget.word.pos,
      synonyms: widget.word.synonyms,
      antonyms: widget.word.antonyms,
    );
  }

  Future<void> _submitAction(EditAction action) async {
    if (action == EditAction.delete) {
      widget.onAction(action, widget.word);
      Navigator.pop(context);
      return;
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      WordModel updatedWord = _getUpdatedWord();
      bool isMitosis = updatedWord.libraryName.startsWith('🧬');

      if (isMitosis && (action == EditAction.update || action == EditAction.copy || action == EditAction.move)) {
        try {
          var existingCards = await isar.wordModels.filter()
              .libraryNameEqualTo(updatedWord.libraryName)
              .wordEqualTo(updatedWord.word)
              .findAll();

          bool hasCollision = false;
          for (var card in existingCards) {
            if (action == EditAction.update && card.id == widget.word.id) continue;

            bool meaningOverlap = updatedWord.meanings.any((m) => card.meanings.contains(m));
            bool exampleOverlap = updatedWord.examples.any((e) => card.examples.contains(e));

            if (meaningOverlap || exampleOverlap) {
              hasCollision = true;
              break;
            }
          }

          if (hasCollision) {
            if (mounted) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Colors.purple.shade900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.purpleAccent, width: 2)),
                  title: Row(
                    children: const [
                      Icon(Icons.biotech, color: Colors.purpleAccent, size: 36),
                      SizedBox(width: 12),
                      Text("DNA Çakışması!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    ],
                  ),
                  content: const Text(
                    "Mitoz havuzu %100 saf ve eşsiz olmalıdır.\n\nGirdiğiniz anlam sistemde, bu kelimeye ait başka bir saf kartta zaten mevcut. Eşsizlik kuralı gereği bu kayıt yapılamaz.\n\nLütfen farklı bir anlam girin veya mevcut kartı silin.",
                    style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
                  ),
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.purple.shade900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("ANLADIM", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    )
                  ],
                )
              );
            }
            return; 
          }
        } catch (e) {
          debugPrint("DNA Kontrol Hatası: $e");
        }
      }

      widget.onAction(action, updatedWord);
      Navigator.pop(context);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Kalıcı Olarak Sil", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("Bu kelimeyi tüm listelerden ve havuzdan kalıcı olarak silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(context);
              _submitAction(EditAction.delete);
            },
            child: const Text("SİL", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSplitBottomSheet() {
    TextEditingController mainWordCtrl = TextEditingController(text: _wordText);
    TextEditingController mainMeaningsCtrl = TextEditingController(text: _meaningControllers.map((c) => c.text).join(', '));
    
    List<Map<String, TextEditingController>> extraCards = [
      {'word': TextEditingController(), 'meanings': TextEditingController()}
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1))
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.5), borderRadius: BorderRadius.circular(10))),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.call_split, color: Colors.teal),
                            SizedBox(width: 8),
                            Text("Kartı Parçala ve Ayrıştır", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text("Bitişik veya hatalı yazılmış kelimeleri ayırarak bağımsız kartlar oluşturun.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ),
                        Expanded(
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.withOpacity(0.3))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("1. Düzeltilmiş Ana Kelime", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 12),
                                    TextField(controller: mainWordCtrl, decoration: _buildInputDeco("Kelime (Örn: Apple)")),
                                    const SizedBox(height: 12),
                                    TextField(controller: mainMeaningsCtrl, decoration: _buildInputDeco("Anlamları (Virgülle Ayırın)")),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...extraCards.asMap().entries.map((entry) {
                                int index = entry.key;
                                var controllers = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: Colors.purple.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.purple.withOpacity(0.3))),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("${index + 2}. Çıkarılan Yeni Kelime", style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                                          if (index > 0)
                                            IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 20), onPressed: () => setModalState(() => extraCards.removeAt(index)))
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(controller: controllers['word'], decoration: _buildInputDeco("Yeni Kelime")),
                                      const SizedBox(height: 12),
                                      TextField(controller: controllers['meanings'], decoration: _buildInputDeco("Anlamları (Virgülle Ayırın)")),
                                    ],
                                  ),
                                );
                              }).toList(),
                              TextButton.icon(
                                onPressed: () => setModalState(() => extraCards.add({'word': TextEditingController(), 'meanings': TextEditingController()})), 
                                icon: const Icon(Icons.add_circle, color: Colors.teal), 
                                label: const Text("Yeni Kelime Yuvası Ekle", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold))
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.auto_fix_high),
                              label: const Text("BÖL VE SİSTEME KAYDET", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                              onPressed: () {
                                List<WordModel> newWordsToInsert = [];
                                for (var extra in extraCards) {
                                  String w = extra['word']!.text.trim();
                                  String m = extra['meanings']!.text.trim();
                                  if (w.isNotEmpty && m.isNotEmpty) {
                                    newWordsToInsert.add(WordModel(
                                      word: w,
                                      meanings: m.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                                      examples: [],
                                      level: _level,
                                      libraryName: _library,
                                      listType: 'all',
                                      srsLevel: 0,
                                      nextReviewDate: 0,
                                      correctCount: 0,
                                      wrongCount: 0,
                                      pos: '', synonyms: [], antonyms: []
                                    ));
                                  }
                                }

                                if (newWordsToInsert.isNotEmpty) {
                                  isar.writeTxnSync(() {
                                    isar.wordModels.putAllSync(newWordsToInsert);
                                  });
                                }

                                setState(() {
                                  _wordText = mainWordCtrl.text.trim();
                                  _meaningControllers.clear();
                                  for (var m in mainMeaningsCtrl.text.split(',')) {
                                    if (m.trim().isNotEmpty) _meaningControllers.add(TextEditingController(text: m.trim()));
                                  }
                                  if (_meaningControllers.isEmpty) _meaningControllers.add(TextEditingController());
                                });

                                Navigator.pop(ctx); 
                                _submitAction(EditAction.update); 
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kelime başarıyla parçalandı ve kaydedildi!"), backgroundColor: Colors.teal));
                              },
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelimeyi Düzenle", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 28),
            tooltip: 'Kalıcı Olarak Sil',
            onPressed: _confirmDelete,
          )
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).primaryColor.withOpacity(0.05), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 220 + MediaQuery.of(context).padding.bottom),
                children: [
                  TextFormField(
                    initialValue: _wordText,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: _buildInputDeco("Düzenlenecek Kelime", icon: Icons.edit_note),
                    validator: (v) => v!.isEmpty ? "Bu alan boş bırakılamaz" : null,
                    onSaved: (v) => _wordText = v!,
                  ),
                  const SizedBox(height: 30),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.g_translate, color: Theme.of(context).primaryColor, size: 22),
                          const SizedBox(width: 8),
                          const Text("Anlamlar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                        child: IconButton(icon: const Icon(Icons.add, color: Colors.green), onPressed: () => setState(() => _meaningControllers.add(TextEditingController()))),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._meaningControllers.map((controller) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: TextFormField(
                      controller: controller,
                      decoration: _buildInputDeco("Anlam #${_meaningControllers.indexOf(controller) + 1}"),
                      validator: (v) => _meaningControllers.indexOf(controller) == 0 && v!.isEmpty ? "En az bir anlam girmelisiniz" : null,
                    ),
                  )),
                  
                  const SizedBox(height: 20),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.format_quote, color: Colors.orange, size: 22),
                          const SizedBox(width: 8),
                          const Text("Örnek Cümleler", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                        child: IconButton(icon: const Icon(Icons.add, color: Colors.orange), onPressed: () => setState(() => _exampleControllers.add(TextEditingController()))),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._exampleControllers.map((controller) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: TextFormField(
                      controller: controller,
                      decoration: _buildInputDeco("Örnek Cümle #${_exampleControllers.indexOf(controller) + 1}"),
                    ),
                  )),

                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _level,
                    decoration: _buildInputDeco("Zorluk Seviyesi", icon: Icons.bar_chart),
                    items: ['A1','A2','B1','B2','C1','C2','Genel'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                    onChanged: (v) => setState(() => _level = v!),
                  ),
                  
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _library,
                    decoration: _buildInputDeco("Kayıt Kütüphanesi", icon: Icons.library_books),
                    items: _currentLibraries.map((e) {
                      if (e == '+ Yeni Kütüphane Oluştur') {
                        return DropdownMenuItem(
                          value: e, 
                          child: Row(
                            children: [
                              const Icon(Icons.add, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(e, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                            ],
                          )
                        );
                      }
                      return DropdownMenuItem(
                        value: e, 
                        child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v == '+ Yeni Kütüphane Oluştur') {
                        _showNewLibraryDialog();
                      } else {
                        setState(() => _library = v!);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 20 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -10))]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text("DEĞİŞİKLİKLERİ GÜNCELLE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: () => _submitAction(EditAction.update),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text("KOPYALA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          onPressed: () => _submitAction(EditAction.copy),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.call_split, size: 18),
                          label: const Text("PARÇALA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          onPressed: _showSplitBottomSheet,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.drive_file_move, size: 18),
                          label: const Text("TAŞI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          onPressed: () => _submitAction(EditAction.move),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
