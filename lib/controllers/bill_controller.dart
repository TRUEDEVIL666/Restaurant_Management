import 'package:cloud_firestore/cloud_firestore.dart';
// Assuming your generic Controller lives here
import 'package:restaurant_management/controllers/template_controller.dart';
// Import the necessary models
import 'package:restaurant_management/models/bill.dart';
import 'package:restaurant_management/models/components/order.dart';

class BillController extends Controller<Bill> {
  BillController._internal() {
    db = FirebaseFirestore.instance.collection('bills');
  }

  static final _instance = BillController._internal();
  factory BillController() => _instance;

  @override
  String getId(Bill item) {
    return item.id ?? '';
  }

  @override
  Map<String, dynamic> toFirestore(Bill object) {
    return object.toFirestore();
  }

  @override
  Bill toObject(DocumentSnapshot<Object?> doc) {
    if (doc.data() != null) {
      return Bill.toObject(doc as DocumentSnapshot<Map<String, dynamic>>);
    } else {
      throw Exception("Document data was null for doc ID: ${doc.id}");
    }
  }

  Future<List<BillOrder>> getOrdersForBill(String billId) async {
    List<BillOrder> orders = [];
    if (billId.isEmpty) return orders;

    try {
      QuerySnapshot ordersSnapshot =
          await db.doc(billId).collection('orders').get();
      orders =
          ordersSnapshot.docs
              .map(
                (doc) => BillOrder.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList();
    } catch (e) {
      print("ERROR GETTING ORDERS for bill ID $billId: $e");
      // Optionally rethrow or return empty list
    }
    return orders;
  }

  Future<bool> updateBillStatus(String billId, String newStatus) async {
    if (billId.isEmpty) return false;
    try {
      await db.doc(billId).update({'status': newStatus});
      return true;
    } catch (e) {
      print("ERROR UPDATING BILL STATUS for ID $billId: $e");
      return false;
    }
  }

  Future<Bill?> getOpenBillByTableNumber(int tableNumber) async {
    try {
      QuerySnapshot querySnapshot =
          await db
              .where('tableNumber', isEqualTo: tableNumber)
              .where('status', isEqualTo: "open")
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Use the updated toObject method which calls Bill.fromFirestore
        return toObject(querySnapshot.docs.first);
      }
    } catch (e) {
      print("ERROR GETTING BILL BY TABLE NUMBER $tableNumber: $e");
    }
    return null;
  }

  Future<double> getTotalBillCostForTable(int tableNumber) async {
    double totalCost = 0.0;
    try {
      Bill? openBill = await getOpenBillByTableNumber(tableNumber);
      if (openBill != null) {
        totalCost = await getTotalBillCost(openBill.id!);
      }
    } catch (e) {
      print("ERROR GETTING TOTAL BILL COST for table $tableNumber: $e");
    }
    return totalCost;
  }

  Future<double> getTotalBillCost(String billId) async {
    double totalCost = 0.0;
    if (billId.isEmpty) {
      print("Error: Cannot calculate total cost for empty bill ID.");
      return totalCost; // Return 0 if ID is invalid
    }

    try {
      CollectionReference ordersRef = db.doc(billId).collection('orders');
      QuerySnapshot ordersSnapshot = await ordersRef.get();

      for (var orderDoc in ordersSnapshot.docs) {
        try {
          BillOrder order = BillOrder.fromFirestore(
            orderDoc as DocumentSnapshot<Map<String, dynamic>>,
          );

          for (var item in order.items) {
            totalCost += (item.quantity * item.unitPrice);
          }
        } catch (e) {
          print(
            "Error processing order item in order ${orderDoc.id} for bill $billId: $e",
          );
          // Decide whether to continue calculation or stop on error
        }
      }
    } catch (e) {
      print("ERROR GETTING TOTAL BILL COST for bill ID $billId: $e");
      // Return 0 or throw exception based on desired error handling
    }

    return totalCost;
  }

  Future<DocumentReference?> addBill(
    int tableNumber, {
    String initialStatus = "open",
  }) async {
    try {
      Bill newBillData = Bill(
        status: initialStatus,
        tableNumber: tableNumber,
        timestamp: Timestamp.now(),
      );
      return await db.add(newBillData.toFirestoreForAdd());
    } catch (e) {
      print("ERROR ADDING BILL for table $tableNumber: $e");
      return null;
    }
  }
}
