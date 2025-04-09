import 'package:cloud_firestore/cloud_firestore.dart';

class Bill {
  final String? id;
  String status;
  int tableNumber;
  Timestamp timestamp;

  Bill({
    this.id,
    required this.status,
    required this.tableNumber,
    required this.timestamp,
  });

  // Standard factory constructor from Firestore DocumentSnapshot
  factory Bill.toObject(DocumentSnapshot doc) {
    return Bill(
      id: doc.id,
      status: doc['status'],
      tableNumber: doc['tableNumber'],
      timestamp: doc['timestamp'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'status': status,
      'tableNumber': tableNumber,
      'timestamp': timestamp,
    };
  }

  Map<String, dynamic> toFirestoreForAdd() {
    return {
      'status': status,
      'tableNumber': tableNumber,
      'timestamp': Timestamp.now(),
    };
  }

  @override
  String toString() {
    return 'Bill{id: $id, status: $status, tableNumber: $tableNumber, timestamp: $timestamp}';
  }
}
