import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDbyYzOoTEgVMIf8ykT9fyXyQx1Albypsk",
    authDomain: "penjualan-91660.firebaseapp.com",
    databaseURL: "https://penjualan-91660-default-rtdb.asia-southeast1.firebasedatabase.app",
    projectId: "penjualan-91660",
    storageBucket: "penjualan-91660.firebasestorage.app",
    messagingSenderId: "927073701727",
    appId: "1:927073701727:web:3cae599e8eedcec591f0ea",
    measurementId: "G-EV1BC1LYS7",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyDbyYzOoTEgVMIf8ykT9fyXyQx1Albypsk",
    authDomain: "penjualan-91660.firebaseapp.com",
    databaseURL: "https://penjualan-91660-default-rtdb.asia-southeast1.firebasedatabase.app",
    projectId: "penjualan-91660",
    storageBucket: "penjualan-91660.firebasestorage.app",
    messagingSenderId: "927073701727",
    appId: "1:927073701727:web:3cae599e8eedcec591f0ea",
  );
}