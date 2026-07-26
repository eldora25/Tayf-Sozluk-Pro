import 'package:isar/isar.dart';

part 'wordnet_entry.g.dart';

@collection
class WordNetEntry {
  Id id = Isar.autoIncrement;

  // Anlık ve hızlı arama yapabilmek için kelime alanını indeksliyoruz
  @Index(type: IndexType.value)
  late String word;

  String? pos;
  late String definition;
  
  List<String>? examples;
  List<String>? synonyms;
  List<String>? antonyms;
}
