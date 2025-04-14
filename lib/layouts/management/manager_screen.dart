import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurant_management/controllers/bill_controller.dart';
import 'package:restaurant_management/firebase_options.dart';
import 'package:restaurant_management/layouts/management/components/bill_management_screen.dart';
import 'package:restaurant_management/layouts/management/components/employee_management_screen.dart';
import 'package:restaurant_management/layouts/management/components/menu_management_screen.dart';
import 'package:restaurant_management/layouts/management/components/table_management_screen.dart';
import 'package:restaurant_management/models/bill.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Enhanced ThemeData ---
    final seedColor = Colors.deepOrange; // Base color for the theme
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light, // Or Brightness.dark for default dark theme
      // You can override specific colors if needed:
      // primary: Colors.redAccent,
      // secondary: Colors.amber,
    );

    final textTheme = GoogleFonts.latoTextTheme(Theme.of(context).textTheme);

    return MaterialApp(
      title: 'Restaurant Manager Pro', // Fancier Title
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true, // Opt-in to Material 3
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface, // Use surface color
          foregroundColor: colorScheme.onSurface, // Text/icon color
          elevation: 2.0,
          titleTextStyle: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary, // Use primary for title maybe?
          ),
          centerTitle: true, // Center title for a more modern look
        ),
        scaffoldBackgroundColor:
            colorScheme.background, // Consistent background
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            textStyle: textTheme.labelLarge,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          // Basic input styling
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        // Define transitions globally (optional)
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            // Add others if needed
          },
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Optional: Define dark theme
      // darkTheme: ThemeData(
      //   colorScheme: ColorScheme.fromSeed(
      //     seedColor: seedColor,
      //     brightness: Brightness.dark,
      //   ),
      //   useMaterial3: true,
      //   textTheme: GoogleFonts.latoTextTheme(ThemeData.dark().textTheme),
      //   // ... configure dark theme specific overrides ...
      // ),
      // themeMode: ThemeMode.system, // Or ThemeMode.light / ThemeMode.dark
      debugShowCheckedModeBanner: false,
      home: const ManagerDashboardScreen(),
    );
  }
}

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  final BillController _billController = BillController();

  // --- Helper for Navigation with Fade Transition ---
  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        // ... (AppBar setup remains the same) ...
        title: const Text('Manager Dashboard'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primaryContainer, colorScheme.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        titleTextStyle: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimary,
        ),
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: Container(
        // ... (Background gradient remains the same) ...
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.surfaceVariant.withOpacity(0.2),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: AnimationLimiter(
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 500),
                childAnimationBuilder:
                    (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                children: [
                  const Text(
                    "Welcome, Manager!",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  _buildDashboardTile(
                    context: context,
                    icon: Icons.restaurant_menu_outlined,
                    label: 'Manage Food Menu',
                    subtitle: 'Add, edit, or remove dishes & combos',
                    color: Colors.orangeAccent.shade100.withOpacity(0.3),
                    onTap: () {
                      _navigateToScreen(context, const MenuManagementScreen());
                      print('Navigating to Menu Management...');
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildDashboardTile(
                    context: context,
                    icon: Icons.groups_outlined,
                    label: 'Manage Employees',
                    subtitle: 'View, add, or manage staff details',
                    color: Colors.lightBlue.shade100.withOpacity(0.3),
                    onTap: () {
                      _navigateToScreen(
                        context,
                        const EmployeeManagementScreen(),
                      );
                      print('Navigating to Employee Management...');
                    },
                  ),
                  const SizedBox(height: 20), // Spacing
                  // --- NEW TILE FOR BILLS PROCESSING ---
                  StreamBuilder<List<Bill>>(
                    stream:
                        _billController
                            .getRequestedBillsStream(), // Use the same stream
                    builder: (context, snapshot) {
                      int pendingCount = 0;
                      if (snapshot.hasData) {
                        pendingCount = snapshot.data!.length;
                      }
                      // Still show the tile even if loading or error, but maybe without badge
                      // Or show a shimmer/placeholder if desired

                      return Badge(
                        // Use the Badge widget
                        label: Text(
                          pendingCount.toString(),
                        ), // Content of the badge
                        isLabelVisible:
                            pendingCount > 0, // Show only if count > 0
                        backgroundColor: Colors.redAccent, // Badge color
                        offset: const Offset(
                          20,
                          -8,
                        ), // Position the badge (adjust as needed)
                        // alignment: AlignmentDirectional.topEnd, // Alternative positioning
                        child: _buildDashboardTile(
                          // Build the original tile
                          context: context,
                          icon: Icons.receipt_long_outlined,
                          label: 'Process Checkouts',
                          subtitle:
                              pendingCount > 0
                                  ? '$pendingCount bill(s) waiting for finalization'
                                  : 'Review and finalize pending customer bills', // Dynamic subtitle
                          color: Colors.deepPurple.shade100.withOpacity(0.3),
                          onTap: () {
                            _navigateToScreen(
                              context,
                              const BillManagementScreen(),
                            );
                            print('Navigating to Bills Processing...');
                          },
                        ),
                      );
                    },
                  ),
                  // --- END Bills Processing Tile ---
                  const SizedBox(height: 20),

                  // --- NEW TILE FOR TABLE MANAGEMENT ---
                  _buildDashboardTile(
                    context: context,
                    icon: Icons.edit_note,
                    label: 'Configure Tables',
                    subtitle: 'Add, remove, or modify table definitions',
                    color: Colors.purple.shade100.withOpacity(0.3),
                    onTap: () {
                      _navigateToScreen(context, const TableManagementScreen());
                      print('Navigating to Table Configuration...');
                    },
                  ),
                  // Add more tiles here if needed
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Fancier Dashboard Tile Widget ---
  Widget _buildDashboardTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    // ... (_buildDashboardTile implementation remains the same) ...
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4.0,
      color: Color.alphaBlend(color, theme.cardColor),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: colorScheme.primary.withOpacity(0.1),
        highlightColor: colorScheme.primary.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: theme.hintColor.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
