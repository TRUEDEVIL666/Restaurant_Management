import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:restaurant_management/controllers/user_controller.dart';
import 'package:restaurant_management/layouts/management/components/dialogs/employee_update_dialog.dart';
import 'package:restaurant_management/models/user.dart';
import 'package:shimmer/shimmer.dart';

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
  final UserController _employeeController = UserController();

  // --- Style Constants ---
  static const double _cardPadding = 16.0;
  static const double _cardMargin = 10.0;
  static const double _borderRadius = 12.0;

  @override
  void initState() {
    super.initState();
    _fetchEmployees(isInitialLoad: true);
  }

  Future<void> _fetchEmployees({bool isInitialLoad = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      // Consider clearing only on explicit refresh/initial load if needed
      // if (isInitialLoad) {
      //   _employees = [];
      // }
    });

    try {
      final List<User> fetchedItems = await _employeeController.getAll();
      if (mounted) {
        setState(() {
          // Sort employees alphabetically by username for consistency
          fetchedItems.sort(
            (a, b) =>
                a.username.toLowerCase().compareTo(b.username.toLowerCase()),
          );
          _employees = fetchedItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = "Failed to fetch employees: $e";
        setState(() {
          _errorMessage = errorMsg;
          _employees = []; // Clear list on error
          _isLoading = false;
        });
        _showSnackBar(errorMsg, isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar(); // Hide previous snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError ? Colors.redAccent.shade700 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.all(10.0),
      ),
    );
  }

  Future<void> _handleDeleteEmployee(User employee) async {
    bool confirmDelete =
        await showDialog<bool>(
          context: context,
          builder:
              (BuildContext context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_borderRadius),
                ),
                title: const Text('Confirm Deletion'),
                content: Text(
                  'Are you sure you want to delete employee "${employee.username}"?',
                ),
                actions: <Widget>[
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

    if (confirmDelete) {
      setState(() => _isLoading = true);
      try {
        // TODO: Make sure your controller uses the ID correctly
        await _employeeController.deleteItem(
          employee.id!,
        ); // Assumed non-null ID
        _showSnackBar('Employee "${employee.username}" deleted successfully.');
        // Optimistic UI update
        if (mounted) {
          setState(() {
            _employees.removeWhere((e) => e.id == employee.id);
            _isLoading = false;
          });
        }
        // Optional: await _fetchEmployees(); // Refresh if optimistic fails often
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showSnackBar('Error deleting employee: $e', isError: true);
          _fetchEmployees(); // Refresh to get correct state after failure
        }
      }
    }
  }

  Future<void> _handleAddOrUpdate({User? existingEmployee}) async {
    final User? resultEmployeeData = await showAddOrUpdateEmployeeDialog(
      context: context,
      existingEmployee: existingEmployee,
    );

    if (resultEmployeeData != null) {
      setState(() => _isLoading = true);
      bool success = false;
      String action = existingEmployee == null ? "add" : "update";
      String actionPast = existingEmployee == null ? "added" : "updated";

      try {
        if (existingEmployee == null) {
          // Ensure your addItem handles password hashing if needed
          await _employeeController.addItem(resultEmployeeData);
        } else {
          // Ensure your updateItem handles password hashing ONLY if password changed
          await _employeeController.updateItem(resultEmployeeData);
        }
        success = true; // Assume success if no error thrown

        if (success) {
          _showSnackBar('Employee ${actionPast} successfully.');
          await _fetchEmployees(); // Refresh list
        }
        // No else needed here, handled by finally if success is false
      } catch (e) {
        success = false; // Explicitly mark as failed on catch
        _showSnackBar('Error ${action}ing employee: $e', isError: true);
      } finally {
        // Show generic failure message ONLY if success is still false
        // and an error wasn't already shown in the catch block (optional).
        // if (!success) {
        //   _showSnackBar('Failed to $action employee.', isError: true);
        // }
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // --- Fancy AppBar ---
      appBar: AppBar(
        title: const Text('Employee Hub 👥'), // Added emoji
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer,
                colorScheme.primary,
              ], // Reversed gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Employees',
            onPressed:
                _isLoading ? null : () => _fetchEmployees(isInitialLoad: true),
          ),
        ],
      ),
      body: _buildBody(theme),
      // --- Fancy FAB ---
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Add Employee',
        onPressed: _isLoading ? null : () => _handleAddOrUpdate(),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Add Employee'),
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        elevation: 6.0,
      ),
    );
  }

  // --- Body Building Logic ---
  Widget _buildBody(ThemeData theme) {
    if (_isLoading && _employees.isEmpty) {
      // --- Shimmer Loading State ---
      return _buildShimmerList();
    } else if (_errorMessage != null && _employees.isEmpty) {
      // --- Error State ---
      return _buildErrorState(theme);
    } else if (!_isLoading && _employees.isEmpty) {
      // --- Empty State ---
      return _buildEmptyState(theme);
    } else {
      // --- List View (potentially with loading overlay for updates) ---
      return Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _fetchEmployees(isInitialLoad: true),
            color: theme.colorScheme.secondary,
            child: _buildAnimatedEmployeeList(theme),
          ),
          // Loading overlay for actions (add/edit/delete)
          if (_isLoading && _employees.isNotEmpty)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      );
    }
  }

  // --- Empty State Widget ---
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 80,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No employees registered yet!',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button below to add the first employee.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- Error State Widget ---
  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.signal_wifi_off_outlined, // Connection error icon
              size: 80,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Connection Problem',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Could not load employee data.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed:
                  _isLoading
                      ? null
                      : () => _fetchEmployees(isInitialLoad: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Shimmer Loading Placeholder ---
  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      enabled: true,
      child: ListView.builder(
        itemCount: 6, // Number of shimmer items
        itemBuilder:
            (_, __) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _cardMargin,
                vertical: _cardMargin / 2,
              ),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_borderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_cardPadding),
                  child: Row(
                    children: [
                      // Placeholder for Avatar
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      // Placeholder for Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: double.infinity,
                              height: 16.0,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              height: 12.0,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 150, // Shorter line
                              height: 12.0,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Placeholder for actions (optional, can be omitted)
                      Container(width: 24, height: 24, color: Colors.white),
                      const SizedBox(width: 8),
                      Container(width: 24, height: 24, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }

  // --- Animated Employee List ---
  Widget _buildAnimatedEmployeeList(ThemeData theme) {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.only(
          bottom: 90,
          top: 5,
        ), // Padding for FAB and top spacing
        itemCount: _employees.length,
        itemBuilder: (context, index) {
          final employee = _employees[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildEmployeeCard(
                  employee,
                  theme,
                  index,
                ), // Pass index for color generation
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Fancy Employee Card ---
  Widget _buildEmployeeCard(User employee, ThemeData theme, int index) {
    final colorScheme = theme.colorScheme;
    // Generate a somewhat consistent color based on index or username hash
    final avatarColor =
        Colors
            .primaries[employee.username.hashCode % Colors.primaries.length]
            .shade300;
    final initials =
        employee.username.length >= 2
            ? employee.username.substring(0, 2).toUpperCase()
            : employee.username.substring(0, 1).toUpperCase();

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: _cardMargin,
        vertical: _cardMargin / 2,
      ),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          print('Tapped on ${employee.username}');
          _handleAddOrUpdate(existingEmployee: employee); // Open edit on tap
        },
        child: Padding(
          padding: const EdgeInsets.all(
            _cardPadding * 0.75,
          ), // Slightly less padding
          child: Row(
            children: [
              // --- Enhanced Avatar ---
              CircleAvatar(
                radius: 26,
                backgroundColor: avatarColor,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // --- Text Details ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.username,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // --- Role Chip ---
                    Chip(
                      label: Text(employee.role),
                      labelStyle: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                      backgroundColor: colorScheme.secondaryContainer
                          .withOpacity(0.7),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      avatar: Icon(
                        _getRoleIcon(employee.role), // Get icon based on role
                        size: 14,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              // --- Action Buttons ---
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_note_outlined,
                      color: Colors.blue.shade600,
                    ),
                    tooltip: 'Edit Employee',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero, // Reduce padding
                    onPressed:
                        _isLoading
                            ? null
                            : () =>
                                _handleAddOrUpdate(existingEmployee: employee),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.person_remove_outlined,
                      color: Colors.redAccent.shade400,
                    ), // More specific icon
                    tooltip: 'Delete Employee',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    onPressed:
                        _isLoading
                            ? null
                            : () => _handleDeleteEmployee(employee),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper to get Role Icon ---
  IconData _getRoleIcon(String role) {
    // TODO: Adjust roles and icons based on your actual application roles
    switch (role.toLowerCase()) {
      case 'manager':
        return Icons.supervisor_account_outlined;
      case 'chef':
        return Icons.kitchen_outlined;
      case 'waiter':
      case 'server':
        return Icons.room_service_outlined;
      case 'cashier':
        return Icons.point_of_sale_outlined;
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.badge_outlined; // Generic employee badge
    }
  }
}
