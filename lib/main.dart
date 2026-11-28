import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'state/staff_app_state.dart';
import 'state/staff_state_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DeliveryCashierApp());
}

class DeliveryCashierApp extends StatefulWidget {
  const DeliveryCashierApp({super.key});

  @override
  State<DeliveryCashierApp> createState() => _DeliveryCashierAppState();
}

class _DeliveryCashierAppState extends State<DeliveryCashierApp> {
  final StaffAppState _staffState = StaffAppState();

  @override
  void dispose() {
    _staffState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StaffStateScope(
      state: _staffState,
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final state = StaffStateScope.of(context);

    // If still initializing from SharedPreferences
    if (!state.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/tropical_gyros_logo.png',
                width: 140,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: AppColors.limeGreenDark,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Persistent login: If user is authenticated, go directly to Home screen!
    if (state.isAuthenticated) {
      return const MainNavigationScreen();
    }

    return const LoginScreen();
  }
}
