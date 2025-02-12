import 'package:cloud_firestore/cloud_firestore.dart';

abstract class Controller<T> {
  late final CollectionReference db;

  Future<T?> getItem(String id) async {
    try {
      DocumentSnapshot doc = await db.doc(id).get();
      return fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('ERROR FETCHING ITEM: $e');
      return null;
    }
  }

  Future<List<T>> getItems() async {
    try {
      QuerySnapshot querySnapshot = await db.get();
      return querySnapshot.docs.map((doc) {
        return fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('ERROR FETCHING ITEMS: $e');
      return [];
    }
  }

  T fromFirestore(String id, Map<String, dynamic> data);
}