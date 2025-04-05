import 'package:restaurant_management/models/dish.dart';

class Order {
  final String? id;
  List<Map<String, dynamic>> dishes;
  final String tableId;

  Order({this.id, List<Map<String, dynamic>>? dishes, required this.tableId})
    : dishes = dishes ?? [];

  factory Order.toObject(String docId, Map<String, dynamic> doc) {
    return Order(
      id: docId,
      dishes: List<Map<String, dynamic>>.from(doc['dishes']),
      tableId: doc['tableId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'dishes': dishes, 'tableId': tableId};
  }

  void addDish(Dish dish) {
    // TODO: DECIDE HOW TO DEAL WITH DUPLICATE DISHES AND TYPE
    dishes.add({'dishName': dish.dishName, 'price': dish.price});
  }

  @override
  String toString() {
    return 'Order{'
        'id: $id, '
        'dishes: $dishes, '
        'tableId: $tableId}';
  }
}
