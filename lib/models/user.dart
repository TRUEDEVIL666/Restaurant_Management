import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String? _id;
  String _username, _password, _phoneNumber;
  List<Timestamp>? _loginHistory;

  User({
    String? id,
    required String username,
    required String password,
    required String phoneNumber,
    List<Timestamp>? loginHistory,
  })  : _id = id,
        _username = username,
        _password = password,
        _phoneNumber = phoneNumber,
        _loginHistory = loginHistory;

  factory User.emptyUser() {
    return User(
      username: '',
      password: '',
      phoneNumber: '',
    );
  }

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
      'username': _username,
      'password': _password,
      'phoneNumber': _phoneNumber,
    };
  }

  String? get getId => _id;

  String get getUsername => _username;

  set setUsername(String value) {
    _username = value;
  }

  get getPassword => _password;

  set setPassword(value) {
    _password = value;
  }

  get getPhoneNumber => _phoneNumber;

  set setPhoneNumber(value) {
    _phoneNumber = value;
  }

  List<Timestamp>? get getLoginHistory => _loginHistory;

  set loginHistory(List<Timestamp> value) {
    _loginHistory = value;
  }

  @override
  String toString() {
    return '$_username has signed in';
  }
}