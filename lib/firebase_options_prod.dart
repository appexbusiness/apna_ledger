// GENERATED for the Production Firebase project (apnaledger-38818).
//
// Web + Android values are filled from the details you provided. iOS is not yet
// configured in Firebase — run `flutterfire configure --project=apnaledger-38818`
// and add GoogleService-Info.plist to complete the iOS target.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class FirebaseOptionsProd {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC1rrxUCF8C9hdkBbp-o6Uv5RLPyAtDI_8',
    appId: '1:934702390982:web:36bd88b5381b931a2d41c7',
    messagingSenderId: '934702390982',
    projectId: 'apnaledger-38818',
    authDomain: 'apnaledger-38818.firebaseapp.com',
    storageBucket: 'apnaledger-38818.firebasestorage.app',
    measurementId: 'G-47XVP0VRHS',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAAzqXa6X7Yj9cSZXwBJlWoPW_qt3zReHs',
    appId: '1:934702390982:android:2d26ebb21a5c33a92d41c7',
    messagingSenderId: '934702390982',
    projectId: 'apnaledger-38818',
    storageBucket: 'apnaledger-38818.firebasestorage.app',
  );

  // iOS not yet configured — placeholder mirrors Android until you run
  // flutterfire configure and add GoogleService-Info.plist.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAAzqXa6X7Yj9cSZXwBJlWoPW_qt3zReHs',
    appId: '1:934702390982:android:2d26ebb21a5c33a92d41c7',
    messagingSenderId: '934702390982',
    projectId: 'apnaledger-38818',
    storageBucket: 'apnaledger-38818.firebasestorage.app',
    iosBundleId: 'com.appexbusiness.apnaledger',
  );
}
