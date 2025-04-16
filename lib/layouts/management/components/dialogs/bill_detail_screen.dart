import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_management/controllers/bill_controller.dart'; // Adjust path
import 'package:restaurant_management/models/bill.dart'; // Adjust path
import 'package:restaurant_management/models/components/order.dart'; // Adjust path
import 'package:shimmer/shimmer.dart';

class BillDetailViewScreen extends StatefulWidget {
  final Bill bill; // Pass the Bill object directly

  const BillDetailViewScreen({super.key, required this.bill});

  @override
  State<BillDetailViewScreen> createState() => _BillDetailViewScreenState();
}

class _BillDetailViewScreenState extends State<BillDetailViewScreen> {
  final BillController _billController = BillController();
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
  );

  // State for fetched orders and calculated totals
  bool _isLoadingOrders = true;
  List<BillOrder> _orders = [];
  double _subtotal = 0.0;
  double _taxAmount = 0.0;
  double _serviceChargeAmount = 0.0;
  double _grandTotal = 0.0;
  String? _ordersErrorMessage;

  // Example constants (match CheckOutScreen or fetch dynamically if needed)
  static const double TAX_RATE = 0.05;
  static const double SERVICE_CHARGE_RATE = 0.10;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoadingOrders = true;
      _ordersErrorMessage = null;
    });

    if (widget.bill.id == null) {
      setState(() {
        _ordersErrorMessage = "Invalid Bill ID.";
        _isLoadingOrders = false;
      });
      return;
    }

    try {
      // Fetch the orders for this specific bill
      final fetchedOrders = await _billController.getOrdersForBill(
        widget.bill.id!,
      );
      if (!mounted) return;

      _orders = fetchedOrders;

      // Calculate totals based on fetched orders
      double calculatedSubtotal = 0.0;
      for (var order in _orders) {
        for (var item in order.items) {
          // Ensure quantity and unitPrice are numbers (add parsing/defaults if needed)
          final quantity = item.quantity;
          final price = item.unitPrice;
          if (quantity is num && price is num) {
            calculatedSubtotal += (quantity * price);
          }
        }
      }

      _subtotal = calculatedSubtotal;
      _taxAmount = _subtotal * TAX_RATE;
      _serviceChargeAmount = _subtotal * SERVICE_CHARGE_RATE;
      _grandTotal =
          _subtotal +
          _taxAmount +
          _serviceChargeAmount; // Assuming no discount shown here

      setState(() {
        _isLoadingOrders = false;
      });
    } catch (e) {
      print("Error loading order details: $e");
      if (!mounted) return;
      setState(() {
        _ordersErrorMessage = 'Error loading order details.';
        _isLoadingOrders = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final DateFormat timestampFormatter = DateFormat('MMM d, yyyy hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text('Bill Details - Table ${widget.bill.tableNumber}'),
        backgroundColor: colorScheme.surfaceContainerHighest,
        elevation: 1,
        actions: [
          // Add status chip/indicator in AppBar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Chip(
              label: Text(widget.bill.status.toUpperCase()),
              labelStyle: textTheme.labelSmall?.copyWith(
                color: _getStatusColor(widget.bill.status, colorScheme).content,
              ),
              backgroundColor:
                  _getStatusColor(widget.bill.status, colorScheme).background,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Bill Info Header ---
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bill ID: ${widget.bill.id ?? 'N/A'}',
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Opened: ${timestampFormatter.format(widget.bill.timestamp.toDate())}',
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Order Items Section ---
            Text('Ordered Items', style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            _buildOrderItemsSection(theme),
            const SizedBox(height: 16),

            // --- Summary Section ---
            _buildSummarySection(theme),
          ],
        ),
      ),
    );
  }

  // --- Build Order Items List ---
  Widget _buildOrderItemsSection(ThemeData theme) {
    if (_isLoadingOrders) {
      return _buildShimmerList(3); // Show shimmer while loading orders
    }
    if (_ordersErrorMessage != null) {
      return Center(
        child: Text(
          _ordersErrorMessage!,
          style: TextStyle(color: theme.colorScheme.error),
        ),
      );
    }
    if (_orders.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('No items found for this bill.')),
        ),
      );
    }

    // Flatten all items from all BillOrder documents for display
    final allItems = _orders.expand((order) => order.items).toList();

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: allItems.length,
        itemBuilder: (context, index) {
          final item = allItems[index];
          // Use data directly from the item map
          final String name = item.name ?? 'Unknown Item';
          final int quantity =
              (item.quantity is num) ? (item.quantity as num).toInt() : 0;
          final double price =
              (item.unitPrice is num)
                  ? (item.unitPrice as num).toDouble()
                  : 0.0;
          return _ItemDetailTile(name: name, quantity: quantity, price: price);
        },
        separatorBuilder:
            (context, index) => Divider(height: 1, indent: 16, endIndent: 16),
      ),
    );
  }

  // --- Build Summary Card ---
  Widget _buildSummarySection(ThemeData theme) {
    final textTheme = theme.textTheme;
    if (_isLoadingOrders) {
      return _buildShimmerSummary(); // Show shimmer while calculating
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bill Summary', style: textTheme.titleLarge),
            const Divider(height: 20),
            _buildSummaryRow(
              textTheme,
              'Subtotal:',
              currencyFormatter.format(_subtotal),
            ),
            _buildSummaryRow(
              textTheme,
              'Tax (${(TAX_RATE * 100).toStringAsFixed(0)}%):',
              '+${currencyFormatter.format(_taxAmount)}',
            ),
            _buildSummaryRow(
              textTheme,
              'Service Charge (${(SERVICE_CHARGE_RATE * 100).toStringAsFixed(0)}%):',
              '+${currencyFormatter.format(_serviceChargeAmount)}',
            ),
            // Add discount row here if applicable and stored/calculable
            const Divider(height: 20),
            _buildSummaryRow(
              textTheme,
              'Grand Total:',
              currencyFormatter.format(_grandTotal),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper for Summary Row ---
  Widget _buildSummaryRow(
    TextTheme textTheme,
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    final style =
        isTotal
            ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
            : textTheme.bodyMedium;
    final valueStyle = style?.copyWith(
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      color: valueColor,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: valueStyle)],
      ),
    );
  }

  // --- Shimmer Placeholders ---
  Widget _buildShimmerList(int count) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        elevation: 0,
        child: Column(
          children: List.generate(
            count,
            (index) => const ListTile(
              leading: CircleAvatar(backgroundColor: Colors.white, radius: 15),
              title: _ShimmerBox(height: 16, width: 120),
              subtitle: _ShimmerBox(height: 12, width: 80),
              trailing: _ShimmerBox(height: 16, width: 50),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerSummary() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ShimmerBox(height: 20, width: 150), // Title
              const Divider(height: 20),
              const _ShimmerRow(),
              const _ShimmerRow(),
              const _ShimmerRow(),
              const Divider(height: 20),
              const _ShimmerRow(isTotal: true),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper for Status Color ---
  ({Color background, Color content}) _getStatusColor(
    String status,
    ColorScheme colorScheme,
  ) {
    switch (status.toLowerCase()) {
      case 'open':
        return (
          background: colorScheme.primaryContainer,
          content: colorScheme.onPrimaryContainer,
        );
      case 'requested':
        return (
          background: Colors.orange.shade100,
          content: Colors.orange.shade900,
        );
      case 'paid':
        return (
          background: Colors.green.shade100,
          content: Colors.green.shade900,
        );
      case 'void':
        return (
          background: Colors.grey.shade300,
          content: Colors.grey.shade800,
        );
      default:
        return (
          background: colorScheme.surfaceVariant,
          content: colorScheme.onSurfaceVariant,
        );
    }
  }
}

// --- Helper Tile for Item Details ---
class _ItemDetailTile extends StatelessWidget {
  final String name;
  final int quantity;
  final double price;
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
  );

  _ItemDetailTile({
    Key? key,
    required this.name,
    required this.quantity,
    required this.price,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemTotal = price * quantity;
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        // Show quantity in avatar
        radius: 15,
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Text(
          quantity.toString(),
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(name),
      subtitle: Text('@ ${currencyFormatter.format(price)} each'),
      trailing: Text(
        currencyFormatter.format(itemTotal),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// --- Helper for Shimmer Boxes ---
class _ShimmerBox extends StatelessWidget {
  final double height;
  final double width;
  const _ShimmerBox({
    Key? key,
    required this.height,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  final bool isTotal;
  const _ShimmerRow({Key? key, this.isTotal = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ShimmerBox(height: isTotal ? 18 : 14, width: 100),
          _ShimmerBox(height: isTotal ? 18 : 14, width: 60),
        ],
      ),
    );
  }
}
