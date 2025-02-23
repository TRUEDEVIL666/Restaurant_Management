import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'template_controller.dart';

class UserController extends Controller<User> {
  UserController._internal() {
    db = FirebaseFirestore.instance.collection('users');
  }

  static final _instance = UserController._internal();
  factory UserController() => _instance;

  @override
  User toObject(String id, Map<String, dynamic> data) {
    return User.fromFirestore(id, data);
  }

  Future<User?> findUser(String username, String password) async {
    try {
      QuerySnapshot querySnapshot = await db
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        QueryDocumentSnapshot doc = querySnapshot.docs.first;
        return toObject(doc.id, doc.data() as Map<String, dynamic>);
      }

      print('USER NOT FOUND');
      return null;
    } catch (e) {
      print('ERROR FINDING USER: $e');
      return null;
    }
  }
}