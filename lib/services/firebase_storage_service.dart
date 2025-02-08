import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

Reference get _firebaseStorage => FirebaseStorage.instance.ref();

class FirebaseStorageService {
  FirebaseStorageService._internal();

  static final _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;

  Future<void> uploadImage(File? image, String? imagePath) async {
    if (image == null || imagePath == null) {
      return;
    }

    try {
      UploadTask uploadTask = _firebaseStorage.child(imagePath).putFile(image);
      await uploadTask;
    } catch (e) {
      print('ERROR UPLOADING IMAGE: $e');
      return;
    }
  }

  Future<String> getImage(String imgPath) async {
    return await _firebaseStorage.child(imgPath).getDownloadURL();
  }
}