import 'package:get_it/get_it.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // TTS global instance (globalTts) ile yönetildiği için buradan kaldırıldı (type hatası önlendi).
  // İleride Firebase/Sentry servisleri buraya eklenecek.
}
