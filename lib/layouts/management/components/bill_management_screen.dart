// lib/layouts/management/bills_processing_screen.dart // Rename file if desired
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for Timestamp
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // For animations
import 'package:intl/intl.dart'; // For date formatting
import 'package:restaurant_management/controllers/bill_controller.dart';
import 'package:restaurant_management/layouts/checkout/check_out_screen.dart';
import 'package:restaurant_management/models/bill.dart';

// Consider renaming the class if it's no longer just for 'processing'
// but more general management of requested bills
class BillManagementScreen extends StatefulWidget {
  const BillManagementScreen({super.key});

  @override
  State<BillManagementScreen> createState() => _BillManagementScreenState();
}

class _BillManagementScreenState extends State<BillManagementScreen> {
  final BillController _billController = BillController();
  final DateFormat _formatter = DateFormat('MMM d, hh:mm a');

  // --- SnackBar function remains useful ---
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // Maybe change title if functionality changed
        title: const Text('Checkout Requests'), // Or 'Pending Bills'
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.primary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        titleTextStyle: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimary,
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: StreamBuilder<List<Bill>>(
        stream:
            _billController.getRequestedBillsStream(), // Connect to the stream
        builder: (context, snapshot) {
          // --- Handle Connection States (Remains the same) ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("StreamBuilder Error: ${snapshot.error}");
            return Center(
              child: Text(
                'Error loading pending bills: ${snapshot.error}',
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // --- Empty State (Remains the same) ---
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All Caught Up!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No pending checkout requests.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // --- Display the List of Bills (Remains the same) ---
          final bills = snapshot.data!;
          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: bills.length,
              itemBuilder: (context, index) {
                final bill = bills[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildBillCard(
                        context,
                        bill,
                      ), // Calls updated card builder
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // --- UPDATED Helper Widget for Bill Card ---
  Widget _buildBillCard(BuildContext context, Bill bill) {
    final theme = Theme.of(context);
    final timeAgo = _formatTimestamp(bill.timestamp); // Format the timestamp

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Icon indicating request (Remains the same)
            Icon(
              Icons.notification_important_outlined,
              color: theme.colorScheme.primary,
              size: 30,
            ),
            const SizedBox(width: 12),
            // Bill Details (Remains the same)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Table ${bill.tableNumber}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Requested: $timeAgo',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),

            // --- REPLACEMENT: Checkout/Details Button ---
            OutlinedButton.icon(
              icon: const Icon(
                Icons.visibility_outlined,
                size: 18,
              ), // Icon for viewing
              label: const Text('Checkout'), // Button text
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    theme
                        .colorScheme
                        .primary, // Use primary color for text/icon
                side: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ), // Border color
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ), // Padding
                textStyle: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ), // Text style
              ),
              onPressed: () {
                // Navigate to the CheckOutScreen, passing the table number
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            CheckOutScreen(tableIndex: bill.tableNumber),
                  ),
                );
              },
            ),
            // --- END REPLACEMENT ---
          ],
        ),
      ),
    );
  }

  // --- Helper to format Timestamp nicely (using intl) ---
  String _formatTimestamp(Timestamp timestamp) {
    // Implementation remains the same
    return _formatter.format(timestamp.toDate());
  }
}
