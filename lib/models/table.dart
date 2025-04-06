import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantTable {
  final String id;
  String? currentBillId;
  bool isOccupied;
  Timestamp? openTime;

  RestaurantTable({
    required this.id,
    this.currentBillId,
    bool? isOccupied,
    this.openTime,
  }) : isOccupied = isOccupied ?? false;

  RestaurantTable.fromMap({
    required this.id,
    required this.currentBillId,
    required this.isOccupied,
    required this.openTime,
  });

  factory RestaurantTable.toObject(DocumentSnapshot doc) {
    return RestaurantTable.fromMap(
      id: doc.id,
      currentBillId: doc['currentBillId'],
      isOccupied: doc['isOccupied'],
      openTime: doc['openTime'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'currentBillId': currentBillId,
      'isOccupied': isOccupied,
      'openTime': null,
    };
  }

  @override
  String toString() {
    return 'Table{'
        'id: $id, '
        'currentBillId: $currentBillId, '
        'isOccupied: $isOccupied, '
        'openTime: $openTime}';
  }
}
