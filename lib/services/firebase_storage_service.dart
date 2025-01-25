import 'package:firebase_storage/firebase_storage.dart';

Reference get firebaseStorage => FirebaseStorage.instance.ref();

class FirebaseStorageService {
  FirebaseStorageService._internal();

  static final _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;

  Future<String> getImage(String imgPath) async {
    return await firebaseStorage.child(imgPath).getDownloadURL();
  }
}
