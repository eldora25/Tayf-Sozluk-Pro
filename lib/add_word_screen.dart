import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'models.dart';
import 'core/db_helper.dart';
import 'core/tts_manager.dart'; 

class AddWordScreen extends StatefulWidget {
  final List<String> availableLibraries;
  final Function(WordModel) onSave;

  const AddWordScreen({super.key, required this.availableLibraries, required this.onSave});

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final _formKey = GlobalKey<FormState>(); 
  String _word = '';
  String _level = 'Genel';
  late String _library;
  late List<String> _currentLibraries;
  
  final List<TextEditingController> _meaningControllers = [TextEditingController()];
  final List<TextEditingController> _exampleControllers = [TextEditingController()];

  List<WordModel> _existingMatches = [];
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _currentLibraries = List.from(widget.availableLibraries);
    _currentLibraries.removeWhere((lib) => lib == 'Tekrarlanması Gerekenler');
    
    if (_currentLibraries.isEmpty) {
      _currentLibraries.add('Varsayılan');
    }
    _library = _currentLibraries.first;
  }

  @override
  void dispose() {
    for (var c in _meaningControllers) { c.dispose(); }
    for (var c in _exampleControllers) { c.dispose(); }
    super.dispose();
  }

  Future<void> _checkExistingWord(String typedWord) async {
    if (typedWord.trim().isEmpty) {
      setState(() => _existingMatches = []);
      return;
    }

    setState(() => _isChecking = true);
    try {
      List<WordModel> matches = await isar.wordModels
          .filter()
          .libraryNameEqualTo(_library)
          .wordEqualTo(typedWord.trim(), caseSensitive: false)
          .findAll();

      setState(() {
        _existingMatches = matches;
        _isChecking = false;
      });
    } catch (e) {
      setState(() => _isChecking = false);
    }
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
          _currentLibraries.add(newLibName);
        }
        _library = newLibName;
      });
      if (_word.isNotEmpty) {
        _checkExistingWord(_word);
      }
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

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Kelime Ekle", style: TextStyle(fontWeight: FontWeight.bold)), elevation: 0),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).primaryColor.withOpacity(0.05), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120 + MediaQuery.of(context).padding.bottom),
                children: [
                  TextFormField(
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: _buildInputDeco("Kelimeyi Yazın", icon: Icons.spellcheck),
                    validator: (v) => v!.isEmpty ? "Bu alan boş bırakılamaz" : null,
                    onChanged: (val) {
                      _word = val;
                      _checkExistingWord(val);
                    },
                    onSaved: (v) => _word = v!,
                  ),
                  
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.only(top: _existingMatches.isNotEmpty ? 16 : 0),
                    height: _existingMatches.isNotEmpty ? null : 0,
                    child: _existingMatches.isNotEmpty 
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(isDark ? 0.2 : 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber.shade700, width: 1.5),
                            boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 24),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Bu kelime '$_library' havuzunda zaten var!",
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                              ..._existingMatches.map((existing) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Mevcut Anlamlar:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  ...existing.meanings.map((m) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Text("• $m", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  )),
                                  if (existing.examples.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    const Text("Mevcut Örnekler:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    ...existing.examples.map((e) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Text("» $e", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14)),
                                    )),
                                  ],
                                ],
                              )),
                            ],
                          ),
                        ) 
                      : const SizedBox.shrink(),
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
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.green),
                          tooltip: "Yeni Anlam Ekle",
                          onPressed: () => setState(() => _meaningControllers.add(TextEditingController())),
                        ),
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
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.orange),
                          tooltip: "Yeni Örnek Ekle",
                          onPressed: () => setState(() => _exampleControllers.add(TextEditingController())),
                        ),
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
                    items: ['A1','A2','B1','B2','C1','C2','Genel','WordNet'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                    onChanged: (v) => setState(() => _level = v!),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _currentLibraries.contains(_library) ? _library : _currentLibraries.first,
                          decoration: _buildInputDeco("Kayıt Kütüphanesi", icon: Icons.library_books),
                          items: _currentLibraries.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) {
                            setState(() => _library = v!);
                            if (_word.isNotEmpty) _checkExistingWord(_word);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1), 
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3))
                        ),
                        child: IconButton(
                          icon: Icon(Icons.add_box, color: Theme.of(context).primaryColor, size: 32),
                          tooltip: "Yeni Kütüphane Oluştur",
                          onPressed: _showNewLibraryDialog,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -10))]
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded, size: 28),
                label: const Text("KELİMEYİ KAYDET", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20), 
                  backgroundColor: Theme.of(context).primaryColor, 
                  foregroundColor: Colors.white, 
                  elevation: 5, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    
                    List<String> meanings = _meaningControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                    List<String> examples = _exampleControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                    
                    WordModel newWord = WordModel(
                      word: _word.trim(),
                      meanings: meanings,
                      examples: examples,
                      level: _level,
                      libraryName: _library,
                    );
                    
                    widget.onSave(newWord);
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
