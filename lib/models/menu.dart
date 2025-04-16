import 'package:cloud_firestore/cloud_firestore.dart';

class FoodMenu {
  final String id;
  String? imgPath;
  bool isCombo;
  bool isActive;
  double price;
  List<Map<String, dynamic>>? foodList;

  FoodMenu({
    required this.id,
    this.imgPath,
    required this.isCombo,
    bool? isActive,
    required this.price,
    this.foodList,
  }) : isActive = isActive ?? true;

  factory FoodMenu.toObject(DocumentSnapshot doc) {
    return FoodMenu(
      id: doc.id,
      imgPath: doc['imgPath'],
      isCombo: doc['isCombo'],
      isActive: doc['isActive'],
      price: doc['price'].toDouble(),
      foodList:
          doc['foodList'] != null
              ? List<Map<String, dynamic>>.from(doc['foodList'])
              : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imgPath': imgPath,
      'isCombo': isCombo,
      'isActive': isActive,
      'price': price,
      'foodList': foodList,
    };
  }
}
