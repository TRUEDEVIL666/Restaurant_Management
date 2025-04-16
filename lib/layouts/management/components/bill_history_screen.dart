import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_management/controllers/bill_controller.dart'; // Adjust path
import 'package:restaurant_management/layouts/management/components/dialogs/bill_detail_screen.dart';
import 'package:restaurant_management/models/bill.dart'; // Adjust path
import 'package:shimmer/shimmer.dart';

class BillHistoryScreen extends StatefulWidget {
  const BillHistoryScreen({super.key});

  @override
  State<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends State<BillHistoryScreen> {
  final BillController _billController = BillController();
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd'); // For display
  final List<String> _statusOptions = [
    'All',
    'open',
    'requested',
    'paid',
    'void',
  ];

  // --- Filter State ---
  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = 'All'; // Default to showing all statuses for the day

  // --- Data State ---
  // Use FutureBuilder, so manage the future directly
  Future<List<Bill>>? _billsFuture;

  @override
  void initState() {
    super.initState();
    _fetchBills(); // Fetch bills for the initial date/status
  }

  // --- Fetch bills based on current filters ---
  void _fetchBills() {
    // Update the future that the FutureBuilder listens to
    setState(() {
      _billsFuture = _billController.getBillsByFilter(
        selectedDate: _selectedDate,
        statusFilter:
            _selectedStatus == 'All'
                ? null
                : _selectedStatus, // Pass null if 'All'
      );
    });
  }

  // --- Show Date Picker ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020), // Adjust start date as needed
      lastDate: DateTime.now().add(
        const Duration(days: 1),
      ), // Allow selecting today
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchBills(); // Re-fetch bills when date changes
    }
  }

  // --- Navigate to Detail View ---
  void _viewBillDetails(Bill bill) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BillDetailViewScreen(bill: bill)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill History'),
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 1,
      ),
      body: Column(
        children: [
          // --- Filter Controls Area ---
          _buildFilterControls(theme, colorScheme),
          const Divider(height: 1, thickness: 1),

          // --- Bill List Area ---
          Expanded(child: _buildBillList(theme, colorScheme)),
        ],
      ),
    );
  }

  // --- Filter Controls Widget ---
  Widget _buildFilterControls(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color:
          theme
              .scaffoldBackgroundColor, // Match background or use a subtle variant
      child: Row(
        children: [
          // Date Picker Button
          Expanded(
            flex: 2, // Give date more space
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(_dateFormatter.format(_selectedDate)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
              ),
              onPressed: () => _selectDate(context),
            ),
          ),
          const SizedBox(width: 12),

          // Status Dropdown
          Expanded(
            flex: 3, // Give status more space
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              items:
                  _statusOptions.map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(
                        status.toUpperCase(),
                      ), // Display status clearly
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedStatus = newValue;
                  });
                  _fetchBills(); // Re-fetch bills when status changes
                }
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  // Consistent border style
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                isDense: true, // Make it less tall
              ),
              style: theme.textTheme.bodyMedium,
              icon: const Icon(Icons.filter_list_alt),
            ),
          ),
        ],
      ),
    );
  }

  // --- Bill List using FutureBuilder ---
  Widget _buildBillList(ThemeData theme, ColorScheme colorScheme) {
    return FutureBuilder<List<Bill>>(
      future: _billsFuture, // Listen to the future set by _fetchBills
      builder: (context, snapshot) {
        // --- Handle Loading State ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show shimmer list while loading
          return _buildShimmerList(6);
        }
        // --- Handle Error State ---
        if (snapshot.hasError) {
          print("Bill History Error: ${snapshot.error}");
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Error loading bills: ${snapshot.error}',
                style: TextStyle(color: colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        // --- Handle Empty State (Data Loaded, but List is Empty) ---
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Bills Found',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No bills match the selected date and status.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // --- Display Bill List ---
        final bills = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(8.0),
          itemCount: bills.length,
          itemBuilder: (context, index) {
            final bill = bills[index];
            return _buildBillListTile(theme, colorScheme, bill);
          },
          separatorBuilder:
              (context, index) =>
                  const SizedBox(height: 4), // Minimal separator
        );
      },
    );
  }

  // --- List Tile for a Single Bill ---
  Widget _buildBillListTile(
    ThemeData theme,
    ColorScheme colorScheme,
    Bill bill,
  ) {
    final DateFormat timeFormatter = DateFormat('hh:mm a');
    final statusColors = _getStatusColor(
      bill.status,
      colorScheme,
    ); // Use helper

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColors.background,
          foregroundColor: statusColors.content,
          child: Text(
            'T${bill.tableNumber}', // Show Table Number
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        title: Text(
          'Bill ID: ${bill.id}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Time: ${timeFormatter.format(bill.timestamp.toDate())}',
        ),
        trailing: Chip(
          // Use chip for status
          label: Text(bill.status.toUpperCase()),
          labelStyle: theme.textTheme.labelSmall?.copyWith(
            color: statusColors.content,
          ),
          backgroundColor: statusColors.background.withOpacity(0.7),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          visualDensity: VisualDensity.compact,
          side: BorderSide.none,
        ),
        onTap: () => _viewBillDetails(bill), // Navigate on tap
        dense: true,
      ),
    );
  }

  // --- Shimmer List Placeholder ---
  Widget _buildShimmerList(int count) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.separated(
        padding: const EdgeInsets.all(8.0),
        itemCount: count,
        itemBuilder:
            (context, index) => Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                ),
                title: const _ShimmerBox(height: 14, width: 150),
                subtitle: const _ShimmerBox(height: 12, width: 80),
                trailing: const _ShimmerBox(height: 24, width: 60),
                dense: true,
              ),
            ),
        separatorBuilder: (context, index) => const SizedBox(height: 4),
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

// --- Helper for Shimmer Boxes (used in BillDetailViewScreen and BillHistoryScreen) ---
// (Keep this helper class defined once, e.g., in a shared utility file or here if simple)
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
