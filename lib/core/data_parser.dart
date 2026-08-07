import 'dart:convert';

List<String> cleanAndSplit(String rawText) {
  List<String> results = [];
  String text = rawText.replaceAll('-III', '').replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').replaceAll('\"', '');
  var parts = text.split(RegExp(r'\|\|\||;|\n|,|\.\s+'));
  for (var p in parts) {
    String clean = p.trim();
    clean = clean.replaceAll(RegExp(r'^[^a-zA-Z0-9çğışöüÇĞIŞÖÜ(]+|[^a-zA-Z0-9çğışöüÇĞIŞÖÜ)]+$'), '').trim();
    clean = clean.replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length > 1 && !['n', 'v', 'adj', 'adv', 'prep', 'conj', 'pron'].contains(clean.toLowerCase())) {
      results.add(clean);
    }
  }
  return results.toSet().toList(); 
}

List<List<String>> parseCsvMultiline(String text) {
  List<List<String>> rows = [];
  List<String> currentRow = [];
  StringBuffer currentCell = StringBuffer();
  bool inQuotes = false;
  for (int i = 0; i < text.length; i++) {
    String c = text[i];
    if (c == '"') {
      if (inQuotes && i + 1 < text.length && text[i + 1] == '"') { currentCell.write('"'); i++; } 
      else { inQuotes = !inQuotes; }
    } else if (c == ',' && !inQuotes) {
      currentRow.add(currentCell.toString().trim()); currentCell.clear();
    } else if ((c == '\n' || c == '\r') && !inQuotes) {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++; 
      currentRow.add(currentCell.toString().trim()); currentCell.clear();
      if (currentRow.where((e) => e.isNotEmpty).isNotEmpty) rows.add(currentRow);
      currentRow = [];
    } else { currentCell.write(c); }
  }
  if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
    currentRow.add(currentCell.toString().trim());
    if (currentRow.where((e) => e.isNotEmpty).isNotEmpty) rows.add(currentRow);
  }
  return rows;
}

List<String> parseLibraryDataInBackground(Map<String, dynamic> params) {
  String content = params['content'];
  String extension = params['extension'];
  String customLibraryName = params['libraryName'];
  String originalFileName = (params['originalFileName'] ?? '').toLowerCase();
  List<String> parsedList = [];

  if (content.startsWith('\uFEFF')) content = content.substring(1);

  try {
    if (extension == 'json') {
      var decoded = json.decode(content);
      List list = decoded is Map ? (decoded['words'] ?? decoded) : decoded;
      for (var item in list) {
        if (item is Map) {
          bool isWordNet = item.containsKey('pos') || item.containsKey('antonyms') || item.containsKey('lemmas') || item.containsKey('synonyms');
          
          if (isWordNet) {
             String wordStr = item['word']?.toString().trim() ?? '';
             String posStr = item['pos']?.toString().trim() ?? '';
             String defStr = item['definition']?.toString().trim() ?? '';
             
             List<String> examplesList = item['examples'] is List ? (item['examples'] as List).map((e) => e.toString()).toList() : [];
             
             List<String> synonymsList = [];
             if (item['synonyms'] is List) synonymsList.addAll((item['synonyms'] as List).map((e) => e.toString()));
             if (item['lemmas'] is List) synonymsList.addAll((item['lemmas'] as List).map((e) => e.toString()));
             synonymsList = synonymsList.toSet().toList(); 
             
             List<String> antonymsList = item['antonyms'] is List ? (item['antonyms'] as List).map((e) => e.toString()).toList() : [];

             if (wordStr.isEmpty || RegExp(r'^\d{8}-').hasMatch(wordStr) || wordStr.contains('[ID:')) {
                 if (synonymsList.isNotEmpty) {
                     wordStr = synonymsList.first;
                 } else {
                     wordStr = "WordNet Term";
                 }
             }

             if (wordStr.isNotEmpty && defStr.isNotEmpty) {
                parsedList.add(json.encode({
                  'word': wordStr,
                  'meanings': [defStr], 
                  'examples': examplesList,
                  'level': 'Genel', 
                  'libraryName': customLibraryName,
                  'correctCount': 0,
                  'wrongCount': 0,
                  'listType': 'all',
                  'srsLevel': 0,
                  'nextReviewDate': 0,
                  'pos': posStr,
                  'synonyms': synonymsList,
                  'antonyms': antonymsList
                }));
             }
          } else {
             List<String> subWords = [];
             String w = item['word']?.toString().trim() ?? '';
             if (!RegExp(r'^\d{8}-').hasMatch(w) && w.isNotEmpty) subWords.add(w);
             if (item['synonyms'] is List) subWords.addAll((item['synonyms'] as List).map((e) => e.toString()));
             if (item['lemmas'] is List) subWords.addAll((item['lemmas'] as List).map((e) => e.toString()));
             String def = item['definition']?.toString() ?? '';
             List<String> mList = item['meanings'] is List ? (item['meanings'] as List).map((e) => e.toString()).toList() : (def.isNotEmpty ? [def] : []);
             List<String> eList = item['examples'] is List ? (item['examples'] as List).map((e) => e.toString()).toList() : [];
             List<String> cleanM = cleanAndSplit(mList.join('|||'));
             List<String> cleanE = cleanAndSplit(eList.join('|||'));

             for (String sw in subWords) {
               sw = sw.replaceAll('_', ' ').trim(); 
               if (sw.length > 1 && cleanM.isNotEmpty) {
                 parsedList.add(json.encode({
                    'word': sw, 
                    'meanings': cleanM, 
                    'examples': cleanE, 
                    'level': item['level']?.toString() ?? 'Genel', 
                    'libraryName': customLibraryName, 
                    'correctCount': 0, 
                    'wrongCount': 0, 
                    'listType': 'all', 
                    'srsLevel': 0, 
                    'nextReviewDate': 0,
                    'pos': '',
                    'synonyms': [],
                    'antonyms': []
                 }));
               }
             }
          }
        }
      }
      return parsedList;
    }

    if (originalFileName.contains('tayf') && extension == 'txt') {
      List<String> lines = const LineSplitter().convert(content);
      for (String line in lines) {
        int colonIdx = line.indexOf(':');
        if (colonIdx != -1) {
          List<String> subWords = line.substring(0, colonIdx).split(RegExp(r'[,/]'));
          List<String> meanings = cleanAndSplit(line.substring(colonIdx + 1));
          for (String w in subWords) {
            w = w.replaceAll('\"', '').trim();
            if (w.length > 1 && meanings.isNotEmpty) {
              parsedList.add(json.encode({'word': w, 'meanings': meanings, 'examples': [], 'level': 'Genel', 'libraryName': customLibraryName, 'correctCount': 0, 'wrongCount': 0, 'listType': 'all', 'srsLevel': 0, 'nextReviewDate': 0, 'pos': '', 'synonyms': [], 'antonyms': []}));
            }
          }
        }
      }
      return parsedList;
    }

    List<List<String>> rows = parseCsvMultiline(content);
    for (List<String> row in rows) {
      if (row.length >= 2) {
        List<String> subWords = row[0].split(RegExp(r'[,/|]'));
        List<String> mList = cleanAndSplit(row[1]);
        List<String> eList = row.length > 2 ? cleanAndSplit(row[2]) : [];
        String level = row.length > 3 ? row[3].replaceAll('"', '').trim() : 'Genel';
        if (level.isEmpty) level = 'Genel';

        if (mList.isNotEmpty) {
          for (String w in subWords) {
            w = w.replaceAll('\"', '').trim();
            w = w.replaceAll(RegExp(r'^[^a-zA-Z0-9çğışöüÇĞIŞÖÜ]+|[^a-zA-Z0-9çğışöüÇĞIŞÖÜ)]+$'), '').trim();
            if (w.length > 1) {
              parsedList.add(json.encode({'word': w, 'meanings': mList, 'examples': eList, 'level': level, 'libraryName': customLibraryName, 'correctCount': 0, 'wrongCount': 0, 'listType': 'all', 'srsLevel': 0, 'nextReviewDate': 0, 'pos': '', 'synonyms': [], 'antonyms': []}));
            }
          }
        }
      }
    }
  } catch (e) {
    parsedList.add(json.encode({'error': "Dosya Okuma Hatası:\n$e"}));
  }
  return parsedList;
}
