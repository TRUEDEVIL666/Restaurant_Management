import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String? id;
  String username, password, email, phoneNumber, role;
  List<Timestamp> loginHistory;

  User({
    this.id,
    required this.username,
    required String password,
    String? role,
    required this.email,
    required this.phoneNumber,
    List<Timestamp>? loginHistory,
  }) : password = hashPassword(password),
       role = role ?? "employee",
       loginHistory = loginHistory ?? [];

  User.fromMap({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.loginHistory,
  });

  factory User.toObject(DocumentSnapshot doc) {
    return User.fromMap(
      id: doc.id,
      username: doc['username'],
      password: doc['password'],
      role: doc['role'],
      email: doc['email'],
      phoneNumber: doc['phoneNumber'],
      loginHistory: List<Timestamp>.from(doc['loginHistory']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'password': password,
      'role': role,
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
    loginHistory.add(timestamp);
  }

  @override
  String toString() {
    return 'User{'
        'id: $id, '
        'username: $username, '
        'password: $password, '
        'role: $role'
        'email: $email, '
        'phoneNumber: $phoneNumber, '
        'loginHistory: $loginHistory}';
  }

  getId() {}
}
