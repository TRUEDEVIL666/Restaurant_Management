import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';

class UserController{
  UserController._internal();

  static final _instance = UserController._internal();
  factory UserController() => _instance;

  static final CollectionReference _db = FirebaseFirestore.instance.collection('users');

  Future<User?> findUser(String username, String password) async {
    try {
      QuerySnapshot querySnapshot = await _db
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        QueryDocumentSnapshot doc = querySnapshot.docs.first;
        User user = User.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
        return user;
      }

      print('USER NOT FOUND');
      return null;
    } catch (e) {
      print('ERROR FINDING USER');
      return null;
    }
  }

  Future<List<User>> getUsers() async {
    try {
      QuerySnapshot querySnapshot = await _db.get();

      return querySnapshot.docs.map((doc) {
        return User.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('ERROR FETCHING USERS: $e');
      return [];
    }
  }

  Future<User> getUser(String id) async {
    try {
      DocumentSnapshot doc = await _db.doc(id).get();
      return User.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('ERROR FETCHING USER: $e');
      return User.emptyUser();
    }
  }
}