import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Waitstaff.dart';

class WaitstaffFirestore {
  static final CollectionReference db = FirebaseFirestore.instance.collection('waitstaff');

  static Future<List<Waitstaff>> getWaitstaffList() async{
    try {
      QuerySnapshot querySnapshot = await db.get();

      return querySnapshot.docs.map((doc) {
        return Waitstaff.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    }
    catch(e) {
      print('Error fetching waitstaff list');
      return [];
    }
  }

  static Future<Waitstaff?> login(String name, String pass) async{
    try {
      QuerySnapshot querySnapshot = await db
          .where('username', isEqualTo: name)
          .where('password', isEqualTo: pass)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        QueryDocumentSnapshot doc = querySnapshot.docs.first;
        return Waitstaff.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      }
      else {
        print('Incorrect Username or Password');
        return null;
      }
    }
    catch(e) {
      print('Error logging in');
      return null;
    }
  }
}