import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/services/firebase_storage_service.dart';
import '../models/dish.dart';

class DishController {
  DishController._internal();

  static final _instance = DishController._internal();
  factory DishController() => _instance;

  static final CollectionReference _db =
      FirebaseFirestore.instance.collection('menu');

  final FirebaseStorageService _storageService = FirebaseStorageService();

  Future<bool> uploadDish(File? image, Dish dish) async {
    try {
      await _storageService.uploadImage(image, dish.imgPath);
      await _db.add(dish.toFirestore());
      return true;
    } catch (e) {
      print('ERROR UPLOADING DISH: $e');
      return false;
    }
  }

  Future<List<Dish>> getMenu() async {
    try {
      QuerySnapshot querySnapshot = await _db.get();

      return querySnapshot.docs.map((doc) {
        return Dish.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('ERROR FETCHING MENU: $e');
      return [];
    }
  }

  Future<Dish> getDish(String id) async {
    try {
      DocumentSnapshot doc = await _db.doc(id).get();
      return Dish.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('ERROR FETCHING DISH: $e');
      return Dish.emptyDish();
    }
  }
}
