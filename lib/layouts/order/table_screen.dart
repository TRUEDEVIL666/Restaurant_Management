// lib/layouts/employee/employee_table_selection_screen.dart

// Flutter Core & UI
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
// Project Specific Imports
import 'package:restaurant_management/controllers/table_controller.dart';
import 'package:restaurant_management/layouts/menu/menu_screen.dart';
import 'package:restaurant_management/layouts/order/combo_selection_screen.dart';
import 'package:restaurant_management/models/table.dart';

// --- IMPORT YOUR ACTUAL NAVIGATION TARGET SCREENS ---
// Make sure these paths are correct and the screens exist

//-----------------------------------------------------
// Placeholder Screens (REMOVE THESE ONCE YOU HAVE ACTUAL SCREENS)
//-----------------------------------------------------

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  final TableController _tableController = TableController();

  // --- Confirmation Dialog Logic (Only for AVAILABLE tables) ---
  Future<void> _confirmAndOpenTable(RestaurantTable table) async {
    // Ensure the widget is still mounted before showing dialog
    if (!mounted) return;

    bool confirmOpen =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text('Open Table ${table.id}'),
              content: const Text(
                'Do you want to start a new order for this table?',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop(false); // Return false on cancel
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor:
                        Theme.of(dialogContext).colorScheme.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Confirm & Open'),
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop(true); // Return true on confirm
                  },
                ),
              ],
            );
          },
        ) ??
        false; // Default to false if dialog is dismissed otherwise

    // If confirmed and widget is still mounted, proceed to navigation
    if (confirmOpen && mounted) {
      // Navigate to the screen for STARTING a new order (e.g., ComboSelectionScreen)
      _navigateToComboSelection(table);
    }
  }

  // --- Navigation for STARTING a NEW Order (Available Table) ---
  Future<void> _navigateToComboSelection(RestaurantTable selectedTable) async {
    print('Confirmed opening Table ID: ${selectedTable.id} for NEW order.');
    selectedTable.checkIn();
    await _tableController.updateItem(selectedTable);

    // --- !!! REPLACE WITH YOUR ACTUAL NAVIGATION !!! ---
    Navigator.push(
      context,
      MaterialPageRoute(
        // Ensure ComboSelectionScreen constructor takes tableId
        builder:
            (context) =>
                ComboSelectionScreen(tableId: selectedTable.id.toString()),
      ),
    );
    // --- End Replace ---
  }

  // --- Navigation for VIEWING/EDITING an EXISTING Order (Occupied Table) ---
  void _navigateToMenuScreen(RestaurantTable selectedTable) {
    if (selectedTable.useDrinkCombo == null) {
      _navigateToComboSelection(selectedTable);
    }

    print(
      'Viewing/editing order for Table ID: ${selectedTable.id} with Combo: ${selectedTable.buffetCombo}',
    );

    // --- !!! REPLACE WITH YOUR ACTUAL NAVIGATION !!! ---
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuScreen(tableId: selectedTable.id.toString()),
      ),
    );
    // --- End Replace ---
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Table'),
        backgroundColor: colorScheme.surfaceContainerHighest,
        elevation: 1,
        // Optional: Add refresh button if needed, though stream handles updates
        // actions: [
        //   IconButton(icon: Icon(Icons.refresh), onPressed: () {/* manual refresh? */})
        // ],
      ),
      body: StreamBuilder<List<RestaurantTable>>(
        stream: _tableController.getAllStream(), // Listen to the stream
        builder: (context, snapshot) {
          // --- Handle Connection States ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Table Stream Error (Employee View): ${snapshot.error}");
            return Center(
              // Improved error display
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading Tables',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Could not fetch table data. Please check connection or try again later.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              // Improved empty state display
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.table_restaurant_outlined,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Tables Available',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please ensure tables are configured in the management section.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // --- Data is available, prepare for Grid ---
          final tables = snapshot.data!;
          // Sort tables for consistent order
          tables.sort((a, b) {
            int? idA = int.tryParse(a.id.replaceAll(RegExp(r'[^0-9]'), ''));
            int? idB = int.tryParse(b.id.replaceAll(RegExp(r'[^0-9]'), ''));
            if (idA != null && idB != null) return idA.compareTo(idB);
            return a.id.compareTo(b.id); // Fallback to string compare
          });

          // Calculate responsive grid column count
          final screenWidth = MediaQuery.of(context).size.width;
          // Adjust 160 for desired card width, clamp ensures min 2, max 4 columns
          final crossAxisCount = (screenWidth / 160).floor().clamp(2, 4);

          // --- Display the Grid of Tables with Animations ---
          return AnimationLimiter(
            // Ensure AnimationLimiter wraps the grid
            child: GridView.builder(
              padding: const EdgeInsets.all(
                16.0,
              ), // Padding for the entire grid
              // Define grid layout properties
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    crossAxisCount, // Number of columns based on calculation
                crossAxisSpacing: 12.0, // Horizontal space between cards
                mainAxisSpacing: 12.0, // Vertical space between cards
                childAspectRatio:
                    1.0, // Aspect ratio (width/height), 1.0 = square
              ),
              itemCount:
                  tables.length, // Total number of tables from stream data
              itemBuilder: (context, index) {
                // Builder function for each grid item
                final table =
                    tables[index]; // Get the table data for this index
                // Configure animations for each grid item
                return AnimationConfiguration.staggeredGrid(
                  position:
                      index, // The item's position in the grid (0, 1, 2...)
                  columnCount:
                      crossAxisCount, // The number of columns in the grid
                  duration: const Duration(
                    milliseconds: 400,
                  ), // How long the animation takes
                  // Define the animation sequence (applied bottom-up)
                  child: ScaleAnimation(
                    // Make the item scale up as it appears
                    delay: Duration(
                      milliseconds: (index % crossAxisCount) * 50,
                    ), // Slight delay per column
                    child: FadeInAnimation(
                      // Make the item fade in as it appears
                      child: _buildEmployeeTableCard(
                        context,
                        table,
                      ), // The actual card widget being animated
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

  // --- Helper Widget for Employee-Facing Table Card ---
  Widget _buildEmployeeTableCard(BuildContext context, RestaurantTable table) {
    final theme = Theme.of(context);
    final bool isOccupied = table.isOccupied;
    final colorScheme = theme.colorScheme;

    // --- Dynamic Visual Properties ---
    final Color cardColor;
    final Color contentColor;
    final Color iconColor;
    final IconData iconData;
    final double elevation;
    final BorderSide borderSide;
    final String statusText;
    String timeInfo = ''; // For occupied duration
    String comboInfo = ''; // For occupied combo hint

    if (isOccupied) {
      // --- Occupied ("Ongoing") State ---
      cardColor = colorScheme.primaryContainer.withOpacity(0.9);
      contentColor = colorScheme.onPrimaryContainer;
      iconColor = colorScheme.primary;
      iconData =
          Icons.restaurant_menu_rounded; // Icon suggesting an active order/menu
      elevation = 2.0;
      borderSide = BorderSide(
        color: colorScheme.primary.withOpacity(0.3),
        width: 1,
      );
      statusText = 'Order Ongoing';

      // Calculate time difference
      if (table.openedAt != null) {
        final duration = DateTime.now().difference(table.openedAt!.toDate());
        if (duration.inMinutes < 1) {
          timeInfo = 'Just sat';
        } else if (duration.inMinutes < 60) {
          timeInfo = '${duration.inMinutes} min ago';
        } else {
          timeInfo =
              '${duration.inHours}h ${duration.inMinutes.remainder(60)}m ago';
        }
      }
      // Get combo info if available
      if (table.buffetCombo != null && table.buffetCombo!.isNotEmpty) {
        comboInfo = table.buffetCombo!; // Display the selected combo
      }
    } else {
      // --- Available State ---
      cardColor = colorScheme.surfaceContainerHighest;
      contentColor = colorScheme.onSurface;
      iconColor = colorScheme.secondary; // Secondary color for available icon
      iconData = Icons.event_seat_rounded; // Icon indicating available seat
      elevation = 3.0;
      borderSide = BorderSide(
        color: colorScheme.secondary.withOpacity(0.6),
        width: 1.5,
      ); // Secondary border
      statusText = 'Available';
    }
    // --- End Dynamic Properties ---

    return Card(
      elevation: elevation,
      color: cardColor,
      clipBehavior: Clip.antiAlias, // Good practice for InkWell ripple clipping
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: borderSide,
      ),
      child: InkWell(
        // *** onTap LOGIC Determines Navigation Target ***
        onTap:
            () =>
                isOccupied
                    // Navigate directly to MenuScreen if occupied, passing ID and combo
                    ? _navigateToMenuScreen(table)
                    // Show confirmation dialog if available, then navigate to Combo Selection
                    : _confirmAndOpenTable(table),
        splashColor: colorScheme.primary.withOpacity(0.1), // Consistent splash
        highlightColor: colorScheme.primary.withOpacity(
          0.05,
        ), // Consistent highlight
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Inner padding for content
          child: Column(
            // Center content vertically and horizontally
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Status Icon
              Icon(iconData, color: iconColor, size: 40),
              const SizedBox(height: 8),

              // Table ID (Main Text)
              Text(
                table.id,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: contentColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Status Text (Available/Ongoing)
              Text(
                statusText,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: contentColor.withOpacity(0.9),
                  fontWeight:
                      isOccupied
                          ? FontWeight.w500
                          : FontWeight.bold, // Adjust weight
                ),
                textAlign: TextAlign.center,
              ),

              // --- Conditional Info for Occupied Tables ---
              // Display Combo Info if available
              if (isOccupied && comboInfo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    comboInfo, // Display combo name
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: contentColor.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // Prevent overflow
                  ),
                ),

              // Display Time Info if available
              if (isOccupied && timeInfo.isNotEmpty)
                Padding(
                  // Adjust top padding if combo info is also showing
                  padding: EdgeInsets.only(
                    top: comboInfo.isNotEmpty ? 0.0 : 4.0,
                  ),
                  child: Text(
                    timeInfo, // Display duration
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: contentColor.withOpacity(0.7),
                      fontStyle: FontStyle.italic, // Italicize time
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              // --- End Conditional Info ---
            ],
          ),
        ),
      ),
    );
  }
}
