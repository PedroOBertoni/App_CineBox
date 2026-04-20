import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// ATENÇÃO: Este arquivo tem chaves temporárias.
// Rode: flutterfire configure --project=cinebox
// para gerar este arquivo com suas chaves reais do Firebase.

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  // Substitua com suas chaves reais após rodar: flutterfire configure
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'SUA_API_KEY_WEB',
    appId: 'SEU_APP_ID_WEB',
    messagingSenderId: 'SEU_MESSAGING_SENDER_ID',
    projectId: 'cinebox',
    authDomain: 'cinebox.firebaseapp.com',
    storageBucket: 'cinebox.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'SUA_API_KEY_ANDROID',
    appId: 'SEU_APP_ID_ANDROID',
    messagingSenderId: 'SEU_MESSAGING_SENDER_ID',
    projectId: 'cinebox',
    storageBucket: 'cinebox.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'SUA_API_KEY_IOS',
    appId: 'SEU_APP_ID_IOS',
    messagingSenderId: 'SEU_MESSAGING_SENDER_ID',
    projectId: 'cinebox',
    storageBucket: 'cinebox.appspot.com',
    iosBundleId: 'com.cinebox.cinebox',
  );
}
