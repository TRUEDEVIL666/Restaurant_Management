class Bill {
  final String id;
  bool status;
  List<Map<String, dynamic>>? orders;
  int tableId;

  Bill({
    required this.id,
    required this.status,
    List<Map<String, dynamic>>? orders,
    required this.tableId,
  }) : orders = orders ?? [];

  factory Bill.toObject(String docId, Map<String, dynamic> doc) {
    return Bill(
      id: docId,
      status: doc['status'],
      orders: List<Map<String, dynamic>>.from(doc['orders']),
      tableId: doc['tableId'],
    );
  }
}
