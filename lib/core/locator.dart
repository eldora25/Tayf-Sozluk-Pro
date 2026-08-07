import 'package:get_it/get_it.dart';
import 'tts_manager.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // TTS Manager'ı Singleton olarak sisteme enjekte ediyoruz
  // İlerleyen aşamalarda FirebaseSyncService gibi servisler de buraya eklenecek.
  locator.registerLazySingleton<TtsManager>(() => TtsManager());
}
