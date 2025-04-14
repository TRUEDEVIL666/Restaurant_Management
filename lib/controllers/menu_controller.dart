import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/controllers/template_controller.dart';
import 'package:restaurant_management/models/menu.dart';

class FoodMenuController extends Controller<FoodMenu> {
  FoodMenuController._internal() {
    db = FirebaseFirestore.instance.collection('menu');
  }

  static final _instance = FoodMenuController._internal();
  factory FoodMenuController() => _instance;

  @override
  FoodMenu toObject(DocumentSnapshot doc) {
    return FoodMenu.toObject(doc);
  }

  @override
  Map<String, dynamic> toFirestore(FoodMenu object) {
    return object.toFirestore();
  }

  @override
  String getId(FoodMenu item) {
    return item.id;
  }
}
