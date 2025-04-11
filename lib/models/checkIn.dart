import 'package:cloud_firestore/cloud_firestore.dart';

class CheckIn {
  final String? id;
  String ip, email, name;
  Timestamp checkInTime;

  CheckIn({
    this.id,
    required this.ip,
    required this.email,
    required this.name,
    required this.checkInTime,
  });

  factory CheckIn.toObject(DocumentSnapshot doc) {
    return CheckIn(
      id: doc.id,
      ip: doc['ip'],
      email: doc['email'],
      name: doc['name'],
      checkInTime: doc['timestamp'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'ip': ip, 'email': email, 'name': name, 'timestamp': checkInTime};
  }
}
