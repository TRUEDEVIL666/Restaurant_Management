import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/controllers/template_controller.dart';
import 'package:restaurant_management/models/check_in.dart';

class CheckInController extends Controller<CheckIn> {
  CheckInController._internal() {
    db = FirebaseFirestore.instance.collection('check_ins');
  }

  static final _instance = CheckInController._internal();
  factory CheckInController() => _instance;

  @override
  String getId(CheckIn item) {
    return item.id!;
  }

  @override
  Map<String, dynamic> toFirestore(CheckIn object) {
    return object.toFirestore();
  }

  @override
  CheckIn toObject(DocumentSnapshot doc) {
    return CheckIn.toObject(doc);
  }
}
