import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantTable {
  final String? id;
  String? buffetCombo, mealType;
  bool isOccupied;
  bool? buffetOptionsLocked, mealTypeLocked, useDrinkCombo;
  int? buffetQuantity;
  Timestamp? openedAt;

  RestaurantTable({
    this.id,
    this.buffetCombo,
    this.mealType,
    this.buffetOptionsLocked,
    bool? isOccupied,
    this.useDrinkCombo,
    this.mealTypeLocked,
    this.buffetQuantity,
    this.openedAt,
  }) : isOccupied = isOccupied ?? false;

  void checkOut() {
    buffetCombo = null;
    mealType = null;
    buffetOptionsLocked = null;
    isOccupied = false;
    mealTypeLocked = null;
    useDrinkCombo = null;
    buffetQuantity = null;
    openedAt = null;
  }

  void checkIn(
    String buffetCombo,
    String mealType,
    bool useDrinkCombo,
    int buffetQuantity,
    bool mealTypeLocked,
    bool buffetOptionsLocked,
  ) {
    this.buffetCombo = buffetCombo;
    this.mealType = mealType;
    this.useDrinkCombo = useDrinkCombo;
    this.buffetQuantity = buffetQuantity;
    this.mealTypeLocked = mealTypeLocked;
    this.buffetOptionsLocked = buffetOptionsLocked;
    isOccupied = true;
    openedAt = Timestamp.now();
  }

  factory RestaurantTable.toObject(DocumentSnapshot doc) {
    return RestaurantTable(
      id: doc.id,
      buffetCombo: doc['buffetCombo'],
      mealType: doc['mealType'],
      buffetOptionsLocked: doc['buffetOptionsLocked'],
      isOccupied: doc['isOccupied'],
      useDrinkCombo: doc['useDrinkCombo'],
      mealTypeLocked: doc['mealTypeLocked'],
      buffetQuantity: doc['buffetQuantity'],
      openedAt: doc['openedAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'buffetCombo': buffetCombo,
      'mealType': mealType,
      'buffetOptionsLocked': buffetOptionsLocked,
      'isOccupied': isOccupied,
      'useDrinkCombo': useDrinkCombo,
      'mealTypeLocked': mealTypeLocked,
      'buffetQuantity': buffetQuantity,
      'openedAt': openedAt,
    };
  }

  @override
  String toString() {
    return 'RestaurantTable{id: $id, '
        'buffetCombo: $buffetCombo, '
        'mealType: $mealType, '
        'buffetOptionsLocked: $buffetOptionsLocked, '
        'isOccupied: $isOccupied, '
        'mealTypeLocked: $mealTypeLocked, '
        'useDrinkCombo: $useDrinkCombo, '
        'buffetQuantity: $buffetQuantity, '
        'openedAt: $openedAt}';
  }
}
