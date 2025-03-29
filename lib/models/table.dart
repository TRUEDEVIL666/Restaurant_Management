class RestaurantTable {
  final String id;
  bool isOccupied;

  RestaurantTable({required this.id, required this.isOccupied});

  factory RestaurantTable.toObject(String docId, Map<String, dynamic> doc) {
    return RestaurantTable(id: docId, isOccupied: doc['isOccupied']);
  }

  Map<String, dynamic> toFirestore() {
    return {'isOccupied': isOccupied};
  }

  @override
  String toString() {
    return 'Table{'
        'id: $id, '
        'isOccupied: $isOccupied}';
  }
}
