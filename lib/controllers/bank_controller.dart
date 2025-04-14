import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/controllers/template_controller.dart';
import 'package:restaurant_management/models/bank.dart';

class BankController extends Controller<Bank> {
  BankController._internal() {
    db = FirebaseFirestore.instance.collection('banks');
  }

  static final _instance = BankController._internal();
  factory BankController() => _instance;

  Future<List<Bank>?> getActiveBanks() async {
    try {
      final QuerySnapshot querySnapshot =
          await db.where('isActive', isEqualTo: true).get();
      final List<Bank> banks =
          querySnapshot.docs.map((doc) => toObject(doc)).toList();
      return banks;
    } catch (e) {
      print('Error fetching active banks: $e');
    }
    return null;
  }

  @override
  String getId(Bank item) {
    return item.id!;
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
