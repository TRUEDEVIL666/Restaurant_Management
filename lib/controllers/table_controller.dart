import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/controllers/template_controller.dart';

import '../models/table.dart';

class TableController extends Controller<RestaurantTable> {
  TableController._internal() {
    db = FirebaseFirestore.instance.collection('tables');
  }

  static final _instance = TableController._internal();
  factory TableController() => _instance;

  @override
  RestaurantTable toObject(String id, Map<String, dynamic> data) {
    return RestaurantTable.toObject(id, data);
  }

  @override
  Map<String, dynamic> toFirestore(RestaurantTable object) {
    return object.toFirestore();
  }

  @override
  String getId(RestaurantTable item) {
    return item.id ?? '';
  }
}
