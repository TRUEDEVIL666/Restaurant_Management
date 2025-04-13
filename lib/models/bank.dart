import 'package:cloud_firestore/cloud_firestore.dart';

class Bank {
  final String? id;
  final String bankCode, accountName, accountNumber;
  final bool isActive;

  Bank({
    this.id,
    required this.bankCode,
    required this.accountName,
    required this.accountNumber,
    bool? isActive,
  }) : isActive = isActive ?? false;

  factory Bank.toObject(DocumentSnapshot doc) {
    return Bank(
      id: doc.id,
      bankCode: doc['bankCode'],
      accountName: doc['accountName'],
      accountNumber: doc['accountNumber'],
      isActive: doc['isActive'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bankCode': bankCode,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'isActive': isActive,
    };
  }

  @override
  String toString() {
    return 'Bank{bankCode: $bankCode, accountName: $accountName, accountNumber: $accountNumber, isActive: $isActive}';
  }
}
