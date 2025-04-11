import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/controllers/template_controller.dart';
import 'package:restaurant_management/models/bank.dart';

class BankController extends Controller<Bank> {
  BankController._internal() {
    db = FirebaseFirestore.instance.collection('banks');
  }

  static final _instance = BankController._internal();
  factory BankController() => _instance;

  @override
  String getId(Bank item) {
    return item.accountName;
  }

  @override
  Map<String, dynamic> toFirestore(Bank object) {
    return object.toFirestore();
  }

  @override
  Bank toObject(DocumentSnapshot doc) {
    return Bank.toObject(doc);
  }
}
