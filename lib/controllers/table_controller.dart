import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/controllers/template_controller.dart';
import 'package:restaurant_management/models/table.dart';

class TableController extends Controller<RestaurantTable> {
  TableController._internal() {
    db = FirebaseFirestore.instance.collection('tables');
  }

  static final _instance = TableController._internal();
  factory TableController() => _instance;

  void switchTableState(RestaurantTable table) {
    table.isOccupied = !table.isOccupied;
    if (table.isOccupied) {
      table.openTime = Timestamp.now();
    } else {
      table.openTime = null;
    }
    updateItem(table);
  }

  @override
  RestaurantTable toObject(DocumentSnapshot doc) {
    return RestaurantTable.toObject(doc);
  }

  @override
  Map<String, dynamic> toFirestore(RestaurantTable object) {
    return object.toFirestore();
  }

  @override
  String getId(RestaurantTable item) {
    return item.id;
  }
}
