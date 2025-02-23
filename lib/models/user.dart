import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String? id;
  String username, password, phoneNumber;
  List<Timestamp>? loginHistory;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.phoneNumber,
    List<Timestamp>? loginHistory,
  }) : loginHistory = loginHistory ?? [];

  factory User.fromFirestore(String docId, Map<String, dynamic> doc) {
    return User(
      id: docId,
      username: doc['username'],
      password: doc['password'],
      phoneNumber: doc['phoneNumber'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'password': password,
      'phoneNumber': phoneNumber,
    };
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, password: $password, phoneNumber: $phoneNumber, loginHistory: $loginHistory}';
  }
}
