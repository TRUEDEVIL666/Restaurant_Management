import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String? id;
  String username, password, email, phoneNumber;
  bool isManager;
  List<Timestamp>? loginHistory;

  User({
    this.id,
    required this.username,
    required String password,
    bool? isManager,
    required this.email,
    required this.phoneNumber,
    List<Timestamp>? loginHistory,
  }) : password = hashPassword(password),
       isManager = isManager ?? false,
       loginHistory = loginHistory ?? [];

  User.fromMap({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
    required this.phoneNumber,
    required this.isManager,
    required this.loginHistory,
  });

  factory User.toObject(String docId, Map<String, dynamic> doc) {
    return User.fromMap(
      id: docId,
      username: doc['username'],
      password: doc['password'],
      isManager: doc['isManager'],
      email: doc['email'],
      phoneNumber: doc['phoneNumber'],
      loginHistory: List<Timestamp>.from(doc['loginHistory']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'password': password,
      'isManager': isManager,
      'email': email,
      'phoneNumber': phoneNumber,
      'loginHistory': loginHistory,
    };
  }

  static String hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  bool checkPassword(String password) {
    return BCrypt.checkpw(password, this.password);
  }

  void addLoginHistory(Timestamp timestamp) {
    loginHistory!.add(timestamp);
  }

  @override
  String toString() {
    return 'User{'
        'id: $id, '
        'username: $username, '
        'password: $password, '
        'isManager: $isManager'
        'email: $email, '
        'phoneNumber: $phoneNumber, '
        'loginHistory: $loginHistory}';
  }
}
