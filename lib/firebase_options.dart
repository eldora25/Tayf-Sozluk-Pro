import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyC0HuwPiltcdy_TR-NvQYPjJixM6clOtuA',
      appId: '1:396433147033:web:4f551a62cc582772cee408',
      messagingSenderId: '396433147033',
      projectId: 'lexis-eldora',
      authDomain: 'lexis-eldora.firebaseapp.com',
      storageBucket: 'lexis-eldora.firebasestorage.app',
    );
  }
}
