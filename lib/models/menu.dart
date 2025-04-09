import 'package:cloud_firestore/cloud_firestore.dart';

class Menu {
  final String id;
  bool isCombo;
  double price;
  List<Map<String, dynamic>>? foodList;

  Menu({
    required this.id,
    required this.isCombo,
    required this.price,
    this.foodList,
  });

  factory Menu.toObject(DocumentSnapshot doc) {
    return Menu(
      id: doc.id,
      isCombo: doc['isCombo'],
      price: doc['price'].toDouble(),
      foodList:
          doc['foodList'] != null
              ? List<Map<String, dynamic>>.from(doc['foodList'])
              : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'isCombo': isCombo, 'price': price, 'foodList': foodList};
  }
}
