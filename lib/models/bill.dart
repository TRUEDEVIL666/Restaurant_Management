import 'package:cloud_firestore/cloud_firestore.dart';

class Bill {
  final String? id;
  String status;
  int tableNumber;
  double? total;
  Timestamp timestamp;

  Bill({
    this.id,
    required this.status,
    required this.tableNumber,
    this.total,
    required this.timestamp,
  });

  // Standard factory constructor from Firestore DocumentSnapshot
  factory Bill.toObject(DocumentSnapshot doc) {
    return Bill(
      id: doc.id,
      status: doc['status'],
      tableNumber: doc['tableNumber'],
      timestamp: doc['timestamp'],
      total: doc['total'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'status': status,
      'tableNumber': tableNumber,
      'timestamp': timestamp,
      'total': total,
    };
  }

  Map<String, dynamic> toFirestoreForAdd() {
    return {
      'status': status,
      'tableNumber': tableNumber,
      'total': total,
      'timestamp': Timestamp.now(),
    };
  }

  @override
  String toString() {
    return 'Bill{id: $id, status: $status, tableNumber: $tableNumber, total: $total, timestamp: $timestamp}';
  }
}
