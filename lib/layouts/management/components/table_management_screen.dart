// lib/layouts/management/table_crud_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:restaurant_management/controllers/table_controller.dart';
import 'package:restaurant_management/models/table.dart';

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  final TableController _tableController = TableController();
  final TextEditingController _tableIdController = TextEditingController();

  // --- Dialog to Add/Edit a Table ---
  Future<void> _showAddEditTableDialog({RestaurantTable? existingTable}) async {
    final bool isEditing = existingTable != null;
    _tableIdController.text =
        isEditing ? existingTable.id ?? '' : ''; // Pre-fill ID if editing

    final String? newTableId = await showDialog<String>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext context) {
        final formKey = GlobalKey<FormState>(); // Key for validation

        return AlertDialog(
          title: Text(isEditing ? 'Edit Table ID' : 'Add New Table'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: _tableIdController,
              autofocus: true,
              // ID cannot be changed once created in this simple example
              readOnly: isEditing,
              decoration: InputDecoration(
                labelText: 'Table ID (e.g., T1, A5)',
                hintText: 'Enter a unique ID',
                border: const OutlineInputBorder(),
                // Dim style if read-only
                fillColor: isEditing ? Colors.grey.shade200 : null,
                filled: isEditing,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Table ID cannot be empty';
                }
                // Optional: Add regex validation for format if needed
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null); // Return null on cancel
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: Text(isEditing ? 'Save (ID cannot change)' : 'Add Table'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // Only pop with value if adding (editing ID isn't allowed here)
                  if (!isEditing) {
                    Navigator.of(context).pop(_tableIdController.text.trim());
                  } else {
                    Navigator.of(context).pop(null); // No change to save for ID
                  }
                }
              },
            ),
          ],
        );
      },
    );

    // --- Process Dialog Result ---
    if (newTableId != null && !isEditing) {
      // --- Add new table ---
      _addNewTable(newTableId);
    }
    // Clear controller after use
    _tableIdController.clear();
  }

  // --- Add New Table Logic ---
  Future<void> _addNewTable(String tableId) async {
    // Check if table ID already exists (optional but good practice)
    // This requires a 'getById' or similar method in your controller or direct check
    // final existing = await _tableController.getById(tableId);
    // if (existing != null) {
    //    _showSnackBar('Table ID "$tableId" already exists.', isError: true);
    //    return;
    // }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Adding Table $tableId...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Create a default new table object
    // Note: Firestore ID will match the one we provide here using 'set' or 'addItemWithId'
    final newTable = RestaurantTable(
      id: tableId, // Set the ID from the dialog
      isOccupied: false, // Default to not occupied
      // Initialize other fields to null or default values as needed
      buffetCombo: null,
      mealType: null,
      buffetOptionsLocked: false,
      useDrinkCombo: false,
      mealTypeLocked: false,
      buffetQuantity: null,
      openedAt: null,
    );

    try {
      // Use addItemWithId to set the specific document ID
      bool success = await _tableController.addItemWithId(newTable);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (success) {
          _showSnackBar('Table "$tableId" added successfully.');
          // StreamBuilder will update the list
        } else {
          _showSnackBar('Failed to add table "$tableId".', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showSnackBar('Error adding table "$tableId": $e', isError: true);
      }
    }
  }

  // --- Delete Table Logic ---
  Future<void> _deleteTable(RestaurantTable table) async {
    if (table.isOccupied) {
      _showSnackBar(
        'Cannot delete an occupied table (${table.id}). Please check it out first.',
        isError: true,
      );
      return;
    }

    bool confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Delete Table "${table.id}"?'),
                content: const Text(
                  'Are you sure? This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    child: const Text('Delete'),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleting Table ${table.id}...'),
          duration: Duration(seconds: 1),
        ),
      );
      try {
        bool success = await _tableController.deleteItem(table.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          if (success) {
            _showSnackBar('Table "${table.id}" deleted.');
            // StreamBuilder will update the list
          } else {
            _showSnackBar(
              'Failed to delete table "${table.id}".',
              isError: true,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _showSnackBar(
            'Error deleting table "${table.id}": $e',
            isError: true,
          );
        }
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide previous
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _tableIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Tables'), // Updated title
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer, // Use theme colors
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
      body: StreamBuilder<List<RestaurantTable>>(
        stream: _tableController.getAllStream(), // Use the stream
        builder: (context, snapshot) {
          // --- Handle Connection States (Same as before) ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No Tables Defined',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add the first table.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // --- Display the List of Tables for CRUD ---
          final tables = snapshot.data!;
          // Sort tables by ID
          tables.sort((a, b) {
            int? idA = int.tryParse(
              a.id?.replaceAll(RegExp(r'[^0-9]'), '') ?? '',
            );
            int? idB = int.tryParse(
              b.id?.replaceAll(RegExp(r'[^0-9]'), '') ?? '',
            );
            if (idA != null && idB != null) return idA.compareTo(idB);
            return a.id!.compareTo(b.id!);
          });

          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildTableCrudTile(context, table),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditTableDialog(), // Open dialog to add
        tooltip: 'Add Table',
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- Helper Widget for Table CRUD Tile ---
  Widget _buildTableCrudTile(BuildContext context, RestaurantTable table) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          foregroundColor: theme.colorScheme.onSecondaryContainer,
          child: const Icon(
            Icons.table_restaurant_sharp,
            size: 20,
          ), // Consistent table icon
        ),
        title: Text(
          'Table ${table.id}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          table.isOccupied ? 'Status: Occupied' : 'Status: Available',
          style: TextStyle(fontSize: 12, color: theme.hintColor),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit button (currently only shows dialog, doesn't allow ID change)
            IconButton(
              icon: Icon(Icons.edit_note, color: Colors.blue.shade600),
              tooltip: 'View Details (ID cannot be changed here)',
              visualDensity: VisualDensity.compact,
              onPressed: () => _showAddEditTableDialog(existingTable: table),
            ),
            // Delete button
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              tooltip: 'Delete Table',
              visualDensity: VisualDensity.compact,
              // Disable delete if occupied
              onPressed: table.isOccupied ? null : () => _deleteTable(table),
            ),
          ],
        ),
      ),
    );
  }
}
