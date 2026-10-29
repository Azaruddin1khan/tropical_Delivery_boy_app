import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'screens/login_screen.dart';
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
        home: const LoginScreen(),
      ),
    );
  }
}
