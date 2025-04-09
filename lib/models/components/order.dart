import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_management/models/components/order_item.dart';

class BillOrder {
  final String id; // Document ID of the specific order document
  final List<OrderItem> items;
  final Timestamp timestamp; // Timestamp for this specific order

  BillOrder({required this.id, required this.items, required this.timestamp});

  // Factory constructor from Firestore DocumentSnapshot
  factory BillOrder.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    // Safely parse the 'items' array from Firestore
    List<OrderItem> parsedItems = [];
    if (data['items'] is List) {
      for (var itemData in (data['items'] as List)) {
        parsedItems.add(OrderItem.fromMap(itemData));
      }
    }

    return BillOrder(
      id: doc.id,
      items: parsedItems,
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // Method to convert Order object to a Map for saving to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      // Convert each OrderItem back to a Map using its toMap method
      'items': items.map((item) => item.toMap()).toList(),
      'timestamp': timestamp,
    };
  }

  // Optional: For creating *new* orders, often using server timestamp
  Map<String, dynamic> toFirestoreForAdd() {
    return {
      'items': items.map((item) => item.toMap()).toList(),
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  @override
  String toString() {
    return 'Order{id: $id, items: $items, timestamp: $timestamp}';
  }
}
