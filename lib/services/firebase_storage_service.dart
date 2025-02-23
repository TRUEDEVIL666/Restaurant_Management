import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

Reference get _firebaseStorage => FirebaseStorage.instance.ref();

class FirebaseStorageService {
  FirebaseStorageService._internal();

  static final _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;

  Future<bool> uploadImage(File? image, String? imagePath) async {
    if (image == null || imagePath == null) {
      return false;
    }

    try {
      UploadTask uploadTask = _firebaseStorage.child(imagePath).putFile(image);
      await uploadTask;
      return true;
    } catch (e) {
      print('ERROR UPLOADING IMAGE: $e');
      return false;
    }
  }

  Future<String> getImage(String imgPath) async {
    return await _firebaseStorage.child(imgPath).getDownloadURL();
  }
}
