import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/controllers/template_controller.dart';
import 'package:restaurant_management/services/firebase_storage_service.dart';
import '../models/dish.dart';

class DishController extends Controller<Dish> {
  DishController._internal() {
    db = FirebaseFirestore.instance.collection('menu');
  }

  static final _instance = DishController._internal();
  factory DishController() => _instance;

  final FirebaseStorageService _storageService = FirebaseStorageService();

  @override
  Dish fromFirestore(String id, Map<String, dynamic> data) =>
      Dish.fromFirestore(id, data);

  Future<bool> uploadDish(File? image, Dish dish) async {
    try {
      await _storageService.uploadImage(image, dish.imgPath);
      await db.add(dish.toFirestore());
      return true;
    } catch (e) {
      print('ERROR UPLOADING DISH: $e');
      return false;
    }
  }
}
