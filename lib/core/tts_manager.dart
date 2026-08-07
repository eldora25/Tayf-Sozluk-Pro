import 'package:flutter_tts/flutter_tts.dart';

final FlutterTts globalTts = FlutterTts();

String getSmartSourceLanguage(String libraryName, String wordText) {
  String name = libraryName.toLowerCase().replaceAll('i̇', 'i').replaceAll('ı', 'i');
  if (name.contains('ing-tr') || name.contains('eng-tr') || name.contains('eng-tur') || name.contains('english-turkish') || name.contains('free-kh') || name.contains('freedict')) return 'en-US';
  if (name.contains('tr-ing') || name.contains('tr-eng') || name.contains('tur-eng') || name.contains('turkish-english')) return 'tr-TR';
  if (name.contains('ing-ing') || name.contains('eng-eng') || name.contains('wordnet')) return 'en-US';
  if (RegExp(r'[çğışöüÇĞIŞÖÜ]').hasMatch(wordText)) return 'tr-TR';
  return 'en-US'; 
}

String getSmartTargetLanguage(String libraryName, String meaningText) {
  String name = libraryName.toLowerCase().replaceAll('i̇', 'i').replaceAll('ı', 'i');
  if (name.contains('ing-tr') || name.contains('eng-tr') || name.contains('eng-tur') || name.contains('english-turkish') || name.contains('free-kh') || name.contains('freedict')) return 'tr-TR';
  if (name.contains('tr-ing') || name.contains('tr-eng') || name.contains('tur-eng') || name.contains('turkish-english')) return 'en-US';
  if (name.contains('ing-ing') || name.contains('eng-eng') || name.contains('wordnet')) return 'en-US';
  if (RegExp(r'[çğışöüÇĞIŞÖÜ]').hasMatch(meaningText)) return 'tr-TR';
  return 'tr-TR'; 
}
