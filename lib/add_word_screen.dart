import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'models.dart';

class AddWordScreen extends StatefulWidget {
  final List<String> availableLibraries;
  final Function(WordModel) onSave;

  const AddWordScreen({super.key, required this.availableLibraries, required this.onSave});

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final _formKey = GlobalKey5 = GlobalKey<FormState>(); // Düzeltildi
  String _word = '';
  String _level = 'Genel';
  late String _library;
  late List<String> _currentLibraries;
  
  final List<TextEditingController> _meaningControllers = [TextEditingController()];
  final List<TextEditingController> _exampleControllers = [TextEditingController()];

  // YENİ: Canlı Eşleşme (Mevcut Kelime Önizlemesi) İçin Değişkenler
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

  // YENİ: Seçili kütüphanede bu kelime var mı diye anlık tarama yapan zeka
  Future<void> _checkExistingWord(String typedWord) async {
    if (typedWord.trim().isEmpty) {
      setState(() => _existingMatches = []);
      return;
    }

    setState(() => _isChecking = true);
    try {
      // ISAR üzerinden seçili kütüphanede ve kelime eşleşmesinde arama yap
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
        title: const Text("Yeni Kütüphane"),
        content: TextField(
          controller: newLibCtrl,
          decoration: const InputDecoration(hintText: "Kütüphane adını girin", border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            onPressed: () {
              if (newLibCtrl.text.trim().isNotEmpty) {
                Navigator.pop(context, newLibCtrl.text.trim());
              }
            }, 
            child: const Text("Oluştur")
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
      // Kütüphane değiştiğinde varsa yazılan kelimeyi tekrar kontrol et
      if (_word.isNotEmpty) {
        _checkExistingWord(_word);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Kelime Ekle")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // KELİME GİRİŞ ALANI VE CANLI TARAMA TETİKLEYİCİSİ
            TextFormField(
              decoration: const InputDecoration(
                labelText: "Kelime", 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.spellcheck),
              ),
              validator: (v) => v!.isEmpty ? "Bu alan boş bırakılamaz" : null,
              onChanged: (val) {
                _word = val;
                _checkExistingWord(val); // Harf değiştikçe eşleşmeyi ara
              },
              onSaved: (v) => _word = v!,
            ),
            
            // YENİ: EĞER KELİME KÜTÜPHANEDE VARSA CANLI ÖNİZLEME KUTUSU
            if (_existingMatches.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade700, width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.05), blurRadius: 10)]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Bu kelime '$_library' kütüphanesinde zaten mevcut!",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    ..._existingMatches.map((existing) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Mevcut Anlamlar:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ...existing.meanings.map((m) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text("• $m", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        )),
                        if (existing.examples.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          const Text("Mevcut Örnekler:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ...existing.examples.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text("» $e", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
                          )),
                        ],
                      ],
                    )),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Anlamlar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => setState(() => _meaningControllers.add(TextEditingController())),
                )
              ],
            ),
            ..._meaningControllers.map((controller) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(hintText: "Kelimenin anlamı...", border: OutlineInputBorder()),
                validator: (v) => _meaningControllers.indexOf(controller) == 0 && v!.isEmpty ? "En az bir anlam girmelisiniz" : null,
              ),
            )),
            
            const SizedBox(height: 10),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Örnek Cümleler (İsteğe Bağlı)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.orange),
                  onPressed: () => setState(() => _exampleControllers.add(TextEditingController())),
                )
              ],
            ),
            ..._exampleControllers.map((controller) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(hintText: "Örnek cümle...", border: OutlineInputBorder()),
              ),
            )),

            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _level,
              decoration: const InputDecoration(labelText: "Seviye", border: OutlineInputBorder()),
              items: ['A1','A2','B1','B2','C1','C2','Genel','WordNet'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _level = v!),
            ),
            
            const SizedBox(height: 20),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currentLibraries.contains(_library) ? _library : _currentLibraries.first,
                    decoration: const InputDecoration(labelText: "Kütüphane", border: OutlineInputBorder()),
                    items: _currentLibraries.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) {
                      setState(() => _library = v!);
                      if (_word.isNotEmpty) _checkExistingWord(_word); // Kütüphane değişince tekrar tara
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    icon: const Icon(Icons.add_box, color: Colors.deepPurple, size: 36),
                    tooltip: "Yeni Kütüphane Ekle",
                    onPressed: _showNewLibraryDialog,
                  ),
                )
              ],
            ),
            
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
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
              child: const Text("KAYDET", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
