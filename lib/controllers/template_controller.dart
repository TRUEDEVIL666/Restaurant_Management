import 'package:cloud_firestore/cloud_firestore.dart';

abstract class Controller<T> {
  late final CollectionReference db;

  Future<bool> addItem(T item) async {
    try {
      await db.add(toFirestore(item));
      return true;
    } catch (e) {
      print('ERROR ADDING ITEM: $e');
      return false;
    }
  }

  Future<bool> addItemWithId(T item) async {
    try {
      await db.doc(getId(item)).set(toFirestore(item));
      return true;
    } catch (e) {
      print('ERROR ADDING ITEM: $e');
      return false;
    }
  }

  Future<T?> getItem(String id) async {
    try {
      DocumentSnapshot doc = await db.doc(id).get();
      return toObject(doc);
    } catch (e) {
      print('ERROR FETCHING ITEM: $e');
      return null;
    }
  }

  Future<List<T>> getAll() async {
    try {
      QuerySnapshot querySnapshot = await db.get();
      return querySnapshot.docs.map((doc) {
        return toObject(doc);
      }).toList();
    } catch (e) {
      print('$T ERROR FETCHING ITEMS: $e');
      return [];
    }
  }

  Stream<List<T>> getAllStream() {
    try {
      return db
          .snapshots()
          .map((querySnapshot) {
            return querySnapshot.docs.map((doc) => toObject(doc)).toList();
          })
          .handleError((error) {
            print("Error in getAllStream for ${T.toString()}: $error");
            return <T>[];
          });
    } catch (e) {
      print("Error setting up getAllStream for ${T.toString()}: $e");
      return Stream.error(e);
    }
  }

  Future<bool> updateItem(T item) async {
    try {
      await db.doc(getId(item)).update(toFirestore(item));
      return true;
    } catch (e) {
      print('ERROR UPDATING ITEM: $e');
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      await db.doc(id).delete();
      return true;
    } catch (e) {
      print('ERROR DELETING ITEM: $e');
      return false;
    }
  }

  T toObject(DocumentSnapshot doc);
  Map<String, dynamic> toFirestore(T object);
  String getId(T item);
}
