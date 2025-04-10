import 'package:flutter/material.dart';
import 'package:restaurant_management/controllers/user_controller.dart';
import 'package:restaurant_management/layouts/management/components/employee_update_dialog.dart';
import 'package:restaurant_management/models/user.dart';
// Import the dialog

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  bool _isLoading = false;
  List<User> _employees = [];
  String? _errorMessage;
  // TODO: Instantiate your actual Employee/User Controller
  final UserController _employeeController = UserController(); // Example

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    _errorMessage = null;
    try {
      // TODO: Call your controller's method to get employees
      final List<User> fetchedItems =
          await _employeeController.getAll(); // Example
      if (mounted) {
        setState(() {
          _employees = fetchedItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error fetching employees: $e";
          _isLoading = false;
        });
        _showSnackBar(_errorMessage!, isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError
                ? Colors.red
                : Theme.of(context).snackBarTheme.backgroundColor,
      ),
    );
  }

  Future<void> _handleDeleteEmployee(String employeeId, String username) async {
    bool confirmDelete =
        await showDialog<bool>(
          context: context,
          builder:
              (BuildContext context) => AlertDialog(
                title: const Text('Confirm Delete'),
                content: Text(
                  'Are you sure you want to delete employee "$username"?',
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmDelete) {
      setState(() => _isLoading = true);
      bool success = false;
      try {
        // TODO: Call your controller's delete method
        await _employeeController.deleteItem(employeeId); // Example
        success = true; // Assume success if no error thrown
        if (success) {
          _showSnackBar('Employee deleted successfully.');
          await _fetchEmployees(); // Refresh list
        }
      } catch (e) {
        success = false; // Explicitly set failure
        _showSnackBar('Error deleting employee: $e', isError: true);
      } finally {
        // Ensure success flag wasn't set if an error occurred before this block
        if (!success) {
          print("Deletion failed or caught error.");
          // _showSnackBar('Failed to delete employee.', isError: true); // Optionally show generic failure
        }
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Employees',
            onPressed: _isLoading ? null : _fetchEmployees,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildEmployeeList(),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Employee',
        onPressed:
            _isLoading
                ? null
                : () async {
                  // --- Call External Dialog to Add ---
                  final User? newEmployeeData =
                      await showAddOrUpdateEmployeeDialog(context: context);

                  // --- Handle Result ---
                  if (newEmployeeData != null) {
                    setState(() => _isLoading = true);
                    bool success = false;
                    try {
                      // TODO: Call controller's add method
                      // Controller needs to handle password hashing based on 'password' field in map
                      await _employeeController.addItem(
                        newEmployeeData,
                      ); // Example
                      success = true; // Assume success if no error thrown
                      if (success) {
                        _showSnackBar('Employee added successfully.');
                        await _fetchEmployees(); // Refresh
                      }
                    } catch (e) {
                      success = false;
                      _showSnackBar('Error adding employee: $e', isError: true);
                    } finally {
                      if (!success) {
                        _showSnackBar('Failed to add employee.', isError: true);
                      }
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    }
                  }
                },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmployeeList() {
    if (_errorMessage != null && _employees.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '$_errorMessage\n\nPull down or tap refresh to try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }
    if (_employees.isEmpty && !_isLoading) {
      return const Center(
        child: Text(
          'No employees found.\nTap the + button to add one!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchEmployees,
      child: ListView.builder(
        itemCount: _employees.length,
        itemBuilder: (context, index) {
          final employee = _employees[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(employee.username.substring(0, 1).toUpperCase()),
              ), // Initial
              title: Text(employee.username),
              subtitle: Text('Role: ${employee.role}\n${employee.email}'),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Edit Employee',
                    onPressed:
                        _isLoading
                            ? null
                            : () async {
                              // --- Call External Dialog to Edit ---
                              final User? updatedEmployeeData =
                                  await showAddOrUpdateEmployeeDialog(
                                    context: context,
                                    existingEmployee: employee,
                                  );

                              // --- Handle Result ---
                              if (updatedEmployeeData != null) {
                                setState(() => _isLoading = true);
                                bool success = false;
                                try {
                                  // TODO: Call controller's update method
                                  // Controller needs to handle password hashing ONLY IF 'password' field exists in map
                                  await _employeeController.updateItem(
                                    updatedEmployeeData,
                                  ); // Example (force unwrap ID assumed safe)
                                  success =
                                      true; // Assume success if no error thrown
                                  if (success) {
                                    _showSnackBar(
                                      'Employee updated successfully.',
                                    );
                                    await _fetchEmployees(); // Refresh
                                  }
                                } catch (e) {
                                  success = false;
                                  _showSnackBar(
                                    'Error updating employee: $e',
                                    isError: true,
                                  );
                                } finally {
                                  if (!success) {
                                    _showSnackBar(
                                      'Failed to update employee.',
                                      isError: true,
                                    );
                                  }
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              }
                            },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete Employee',
                    onPressed:
                        _isLoading
                            ? null
                            : () => _handleDeleteEmployee(
                              employee.id!,
                              employee.username,
                            ), // Force unwrap ID assumed safe
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
