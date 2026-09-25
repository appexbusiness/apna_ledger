// GENERATED for the QA / UAT Firebase project (apnaledgerqa).
//
// The web config below is taken from the details you provided. The android/ios
// values must be filled in by running:
//     flutterfire configure --project=apnaledgerqa
// which also writes the platform google-services files. Until then the web
// target works out of the box and the mobile targets fall back to the shared
// web app id (fine for early QA, replace before store submission).
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class FirebaseOptionsQa {
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
    apiKey: 'AIzaSyDJX6t9LbCSjN49LvJZ_fiS-m1Yc-WDdhY',
    appId: '1:839704694234:web:cff47abddeca0eb95e44e3',
    messagingSenderId: '839704694234',
    projectId: 'apnaledgerqa',
    authDomain: 'apnaledgerqa.firebaseapp.com',
    storageBucket: 'apnaledgerqa.firebasestorage.app',
    measurementId: 'G-51TZJKFCX0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCV0_YZ8jFHgbv30CcV4tcb-6i63CWS23w',
    appId: '1:839704694234:android:2153b284ef1a25515e44e3',
    messagingSenderId: '839704694234',
    projectId: 'apnaledgerqa',
    storageBucket: 'apnaledgerqa.firebasestorage.app',
  );

  // iOS not yet configured in Firebase. Run `flutterfire configure` and add the
  // GoogleService-Info.plist to fill these in for the QA bundle id.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCV0_YZ8jFHgbv30CcV4tcb-6i63CWS23w',
    appId: '1:839704694234:android:2153b284ef1a25515e44e3',
    messagingSenderId: '839704694234',
    projectId: 'apnaledgerqa',
    storageBucket: 'apnaledgerqa.firebasestorage.app',
    iosBundleId: 'com.appexbusiness.apnaledgerqa',
  );
}
