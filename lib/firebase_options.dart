import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAC1IlqEfae6EzXy_Aa-lAg7y0X1PpV3Bg',
    appId: '1:467115673659:android:3eb5132efd42e9d3d5341e',
    messagingSenderId: '467115673659',
    projectId: 'hot-dish--mad-2',
    databaseURL:
        'https://hot-dish--mad-2-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'hot-dish--mad-2.firebasestorage.app',
  );
}
