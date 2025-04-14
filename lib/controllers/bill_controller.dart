import 'package:cloud_firestore/cloud_firestore.dart';
// Assuming your generic Controller lives here
import 'package:restaurant_management/controllers/template_controller.dart';
// Import the necessary models
import 'package:restaurant_management/models/bill.dart';
import 'package:restaurant_management/models/components/order.dart'; // Keep if used elsewhere

class BillController extends Controller<Bill> {
  BillController._internal() {
    db = FirebaseFirestore.instance.collection('bills');
  }

  static final _instance = BillController._internal();
  factory BillController() => _instance;

  @override
  String getId(Bill item) {
    // Ensure null safety - throw error or return default if id is unexpectedly null
    if (item.id == null) {
      throw ArgumentError("Bill ID cannot be null when getting ID");
      // Alternatively: return ''; but this might hide issues
    }
    return item.id!;
  }

  @override
  Map<String, dynamic> toFirestore(Bill object) {
    return object.toFirestore();
  }

  @override
  Bill toObject(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?; // Use safer casting
    if (data != null) {
      // Cast the DocumentSnapshot before passing to factory
      return Bill.toObject(doc as DocumentSnapshot<Map<String, dynamic>>);
    } else {
      throw Exception("Document data was null for doc ID: ${doc.id}");
    }
  }

  Stream<List<Bill>> getRequestedBillsStream() {
    // ... (implementation remains the same) ...
    try {
      return db
          .where('status', isEqualTo: 'requested') // Filter by status
          .orderBy('timestamp', descending: false) // Oldest requests first
          .snapshots() // Get the stream of query snapshots
          .map((querySnapshot) {
            // Map the stream
            // Convert each document snapshot to a Bill object
            return querySnapshot.docs.map((doc) => toObject(doc)).toList();
          })
          .handleError((error, stackTrace) {
            // Add stackTrace for better debugging
            print("Error in requested bills stream: $error\n$stackTrace");
            // Optionally emit an empty list or rethrow, depending on desired behavior
            return <Bill>[];
          });
    } catch (e, stackTrace) {
      // Add stackTrace
      print("Error setting up requested bills stream: $e\n$stackTrace");
      // Return a stream that emits an error or an empty list immediately
      return Stream.error(e); // Propagate error
    }
  }

  Stream<Bill?> getBillStreamByTableNumber(int tableNumber) {
    try {
      return db
          .where('tableNumber', isEqualTo: tableNumber)
          .where('status', whereIn: ['open', 'requested'])
          .limit(1)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              return null;
            } else {
              try {
                return toObject(snapshot.docs.first);
              } catch (e) {
                print("Error converting bill document in stream: $e");
                return null; // Handle potential conversion errors
              }
            }
          })
          .handleError((error) {
            print("Error in getBillStreamByTableNumber: $error");
            // Emit null or handle the error as needed for the UI
            return null;
          });
    } catch (e) {
      print("Error setting up getBillStreamByTableNumber: $e");
      // Return a stream that emits null or an error
      return Stream.value(null).handleError((_) => true); // Or Stream.error(e);
    }
  }

  Future<bool> updateBillTotal(String billId, double newTotal) async {
    if (billId.isEmpty) {
      print("Error updating bill total: Bill ID cannot be empty.");
      return false;
    }
    if (newTotal < 0) {
      print("Error updating bill total: New total cannot be negative.");
      return false;
    }

    try {
      await db.doc(billId).update({'total': newTotal});
      print("Bill $billId total updated to $newTotal");
      return true;
    } catch (e, stackTrace) {
      print("ERROR UPDATING BILL TOTAL for ID $billId: $e\n$stackTrace");
    }
    return false;
  }

  Future<List<BillOrder>> getOrdersForBill(String billId) async {
    // ... (implementation remains the same, consider adding more error details) ...
    List<BillOrder> orders = [];
    if (billId.isEmpty) {
      print("Warning: getOrdersForBill called with empty billId.");
      return orders;
    }

    try {
      // Get reference to the subcollection
      CollectionReference ordersRef = db.doc(billId).collection('orders');
      // Fetch the documents
      QuerySnapshot ordersSnapshot =
          await ordersRef
              .orderBy('timestamp')
              .get(); // Optional: order by timestamp

      // Map documents to BillOrder objects
      orders =
          ordersSnapshot.docs
              .map((doc) {
                // Ensure casting is safe
                final data = doc.data() as Map<String, dynamic>?;
                if (data != null) {
                  return BillOrder.fromFirestore(
                    doc as DocumentSnapshot<Map<String, dynamic>>,
                  );
                } else {
                  print(
                    "Warning: Order document ${doc.id} in bill $billId has null data. Skipping.",
                  );
                  // Return a dummy or throw an error if this shouldn't happen
                  // For now, filter it out by returning null and using whereType later maybe
                  return null;
                }
              })
              // Filter out any potential nulls from failed mappings
              .whereType<BillOrder>()
              .toList();
    } catch (e, stackTrace) {
      print("ERROR GETTING ORDERS for bill ID $billId: $e\n$stackTrace");
      // Optionally rethrow or return empty list
    }
    return orders;
  }

  Future<bool> addOrderToBill(
    String billId,
    List<Map<String, dynamic>> orderItems,
  ) async {
    // 1. Validate inputs
    if (billId.isEmpty) {
      print("Error adding order: Bill ID cannot be empty.");
      return false;
    }
    if (orderItems.isEmpty) {
      print("Error adding order: Order items list cannot be empty.");
      // Optionally, allow empty orders if that's a valid state, but usually not
      return false;
    }

    try {
      // 2. Get a reference to the 'orders' subcollection for the specific bill document
      CollectionReference ordersSubcollection = db
          .doc(billId)
          .collection('orders');

      // 3. Prepare the data for the new order document
      final Map<String, dynamic> newOrderData = {
        'timestamp': Timestamp.now(), // Record when this order batch was placed
        'items': orderItems,
      };

      // 4. Add the new document to the subcollection
      await ordersSubcollection.add(newOrderData);

      print("Order successfully added to bill $billId");
      return true; // Indicate success
    } catch (e, stackTrace) {
      // 5. Handle potential errors during the Firestore operation
      print("Error adding order to bill $billId: $e\n$stackTrace");
    }
    return false;
  }

  Future<bool> updateBillStatus(String billId, String newStatus) async {
    // ... (implementation remains the same) ...
    if (billId.isEmpty) {
      print("Error updating bill status: Bill ID cannot be empty.");
      return false;
    }
    try {
      await db.doc(billId).update({'status': newStatus});
      print("Bill $billId status updated to $newStatus");
      return true;
    } catch (e, stackTrace) {
      print("ERROR UPDATING BILL STATUS for ID $billId: $e\n$stackTrace");
      return false;
    }
  }

  Future<Bill?> getOpenBillByTableNumber(int tableNumber) async {
    return getStatusBillByTableNumber(tableNumber, "open");
  }

  Future<Bill?> getRequestedBillByTableNumber(int tableNumber) async {
    return getStatusBillByTableNumber(tableNumber, "requested");
  }

  Future<Bill?> getStatusBillByTableNumber(
    int tableNumber,
    String status,
  ) async {
    // ... (implementation remains the same, consider adding stack trace to error) ...
    try {
      QuerySnapshot querySnapshot =
          await db
              .where('tableNumber', isEqualTo: tableNumber)
              .where('status', isEqualTo: status)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return toObject(querySnapshot.docs.first);
      }
    } catch (e, stackTrace) {
      print(
        "ERROR GETTING BILL BY TABLE NUMBER $tableNumber (status: $status): $e\n$stackTrace",
      );
    }
    return null;
  }

  Future<double> getTotalBillCost(String billId) async {
    // ... (implementation remains the same, consider adding more specific error details) ...
    double totalCost = 0.0;
    if (billId.isEmpty) {
      print("Error: Cannot calculate total cost for empty bill ID.");
      return totalCost;
    }

    try {
      CollectionReference ordersRef = db.doc(billId).collection('orders');
      QuerySnapshot ordersSnapshot = await ordersRef.get();

      if (ordersSnapshot.docs.isEmpty) {
        print("No orders found for bill $billId to calculate cost.");
        return 0.0; // Return 0 if there are no orders yet
      }

      for (var orderDoc in ordersSnapshot.docs) {
        try {
          // Cast safely
          final data = orderDoc.data() as Map<String, dynamic>?;
          if (data == null) {
            print(
              "Warning: Order document ${orderDoc.id} has null data in bill $billId. Skipping cost calculation for this order.",
            );
            continue; // Skip this order doc
          }
          // Use BillOrder.fromFirestore - MAKE SURE BillOrder and BillOrderItem exist and work
          BillOrder order = BillOrder.fromFirestore(
            orderDoc as DocumentSnapshot<Map<String, dynamic>>,
          );

          if (order.items.isEmpty) {
            print(
              "Warning: Order ${orderDoc.id} has no items in bill $billId.",
            );
            continue; // Skip if order has no items
          }

          for (var item in order.items) {
            // Basic validation for item data
            if (item.quantity < 0 || item.unitPrice < 0) {
              print(
                "Warning: Invalid quantity (${item.quantity}) or price (${item.unitPrice}) for item '${item.name}' in order ${orderDoc.id}, bill $billId. Skipping item.",
              );
              continue;
            }
            totalCost += (item.quantity * item.unitPrice);
          }
        } catch (e, stackTrace) {
          print(
            "Error processing order document ${orderDoc.id} for bill $billId: $e\n$stackTrace",
          );
          // Decide whether to continue calculation or stop on error
        }
      }
    } catch (e, stackTrace) {
      print(
        "ERROR GETTING TOTAL BILL COST for bill ID $billId: $e\n$stackTrace",
      );
      // Return 0 or throw exception based on desired error handling
    }

    // Round to 2 decimal places (optional but good for currency)
    return double.parse(totalCost.toStringAsFixed(2));
  }

  Future<DocumentReference?> addBill(
    int tableNumber, {
    String initialStatus = "open",
  }) async {
    // ... (implementation remains the same) ...
    try {
      Bill newBillData = Bill(
        status: initialStatus,
        tableNumber: tableNumber,
        timestamp: Timestamp.now(), // Set timestamp on creation
      );
      // Use the toFirestoreForAdd method if it correctly sets the timestamp
      // Otherwise, ensure timestamp is included as shown above
      print(
        "Adding new bill for table $tableNumber with status $initialStatus",
      );
      return await db.add(
        newBillData.toFirestoreForAdd(),
      ); // Assumes toFirestoreForAdd sets timestamp
    } catch (e, stackTrace) {
      print("ERROR ADDING BILL for table $tableNumber: $e\n$stackTrace");
      return null;
    }
  }
}
