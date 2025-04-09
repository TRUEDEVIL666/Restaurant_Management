class OrderItem {
  final String name;
  final int quantity;
  final double unitPrice;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  // Factory to create an OrderItem from a Map (like those in the Firestore array)
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] as String? ?? 'Unknown Item',
      quantity: map['quantity'] as int? ?? 0,
      unitPrice: map['unitPrice'].toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'quantity': quantity, 'unitPrice': unitPrice};
  }

  @override
  String toString() {
    return 'OrderItem{name: $name, quantity: $quantity, unitPrice: $unitPrice}';
  }
}
