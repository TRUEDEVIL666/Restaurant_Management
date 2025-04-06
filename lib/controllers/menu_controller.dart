import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/controllers/template_controller.dart';
import 'package:restaurant_management/models/menu.dart';

class FoodMenuController extends Controller<Menu> {
  FoodMenuController._internal() {
    db = FirebaseFirestore.instance.collection('menu');
  }

  static final _instance = FoodMenuController._internal();
  factory FoodMenuController() => _instance;

  @override
  Menu toObject(DocumentSnapshot doc) {
    return Menu.toObject(doc);
  }

  @override
  Map<String, dynamic> toFirestore(Menu object) {
    return object.toFirestore();
  }

  @override
  String getId(Menu item) {
    return item.id;
  }
}
