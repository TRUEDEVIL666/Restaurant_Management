import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/controllers/template_controller.dart';
import 'package:restaurant_management/models/user.dart';

class UserController extends Controller<User> {
  UserController._internal() {
    db = FirebaseFirestore.instance.collection('users');
  }

  static final _instance = UserController._internal();
  factory UserController() => _instance;

  // Functions to check validity of username, phone, and email
  Future<bool> checkUsername(String username) async {
    return _checkValidity(username, 'username');
  }

  Future<bool> checkPhone(String phone) async {
    return _checkValidity(phone, 'phone');
  }

  Future<bool> checkEmail(String email) async {
    return _checkValidity(email, 'email');
  }

  Future<bool> _checkValidity(String content, String field) async {
    try {
      QuerySnapshot querySnapshot =
          await db.where(field, isEqualTo: content).get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print("ERROR CHECKING ${field.toUpperCase()}: $e");
    }
    return false;
  }

  // Functions to login with username or phone
  Future<User?> login(String content, String password) async {
    return await loginEmail(content, password) ?? loginPhone(content, password);
  }

  Future<User?> loginEmail(String email, String password) async {
    return await loginField(email, password, 'email');
  }

  Future<User?> loginPhone(String phone, String password) async {
    return await loginField(phone, password, 'phoneNumber');
  }

  Future<User?> loginField(
    String content,
    String password,
    String field,
  ) async {
    try {
      QuerySnapshot querySnapshot =
          await db.where(field, isEqualTo: content).get();

      if (querySnapshot.docs.isNotEmpty) {
        QueryDocumentSnapshot doc = querySnapshot.docs.first;

        User user = toObject(doc);

        if (user.checkPassword(password)) {
          user.addLoginHistory(Timestamp.now());
          db.doc(doc.id).update({'loginHistory': user.loginHistory});
          return user;
        }
      }
    } catch (e) {
      print('ERROR FINDING USER: $e');
    }
    return null;
  }

  @override
  User toObject(DocumentSnapshot doc) {
    return User.toObject(doc);
  }

  @override
  Map<String, dynamic> toFirestore(User object) {
    return object.toFirestore();
  }

  @override
  String getId(User item) {
    return item.id ?? '';
  }
}
