import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/demo_banner.dart';
import '../core/widgets/primary_button.dart';
import '../models/staff_user.dart';
import '../state/staff_state_scope.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(
    text: 'driver.devon@tropicalgyros.com',
  );
  final _passwordController = TextEditingController(text: 'StaffPass2026!');
  bool _obscurePassword = true;
  bool _isLoading = false;
  StaffRole _selectedRole = StaffRole.deliveryDriver;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate brief network delay
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final state = StaffStateScope.read(context);
    final success = state.login(
      username: _usernameController.text,
      password: _passwordController.text,
      role: _selectedRole,
    );

    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  void _autofillDriver() {
    setState(() {
      _selectedRole = StaffRole.deliveryDriver;
      _usernameController.text = 'driver.devon@tropicalgyros.com';
      _passwordController.text = 'StaffPass2026!';
    });
  }

  void _autofillCashier() {
    setState(() {
      _selectedRole = StaffRole.cashier;
      _usernameController.text = 'cashier.maya@tropicalgyros.com';
      _passwordController.text = 'StaffPass2026!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const DemoBanner(
                    label: 'STAFF PORTAL • UI Prototype (No Real Auth / API)',
                  ),
                  const SizedBox(height: 16),

                  // Brand Emblem
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppColors.tropicalYellowLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.tropicalYellow,
                          width: 2.5,
                        ),
                      ),
                      child: const Center(
                        child: Text('🌴', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // App Title
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.appSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Role Selector Segment
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                              () => _selectedRole = StaffRole.deliveryDriver,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedRole == StaffRole.deliveryDriver
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow:
                                    _selectedRole == StaffRole.deliveryDriver
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.06,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delivery_dining_rounded,
                                    size: 18,
                                    color:
                                        _selectedRole ==
                                            StaffRole.deliveryDriver
                                        ? AppColors.tropicalYellowDark
                                        : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Delivery Staff',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          _selectedRole ==
                                              StaffRole.deliveryDriver
                                          ? AppColors.textDark
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                              () => _selectedRole = StaffRole.cashier,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedRole == StaffRole.cashier
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _selectedRole == StaffRole.cashier
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.06,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.storefront_rounded,
                                    size: 18,
                                    color: _selectedRole == StaffRole.cashier
                                        ? AppColors.oceanBlue
                                        : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Counter Cashier',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedRole == StaffRole.cashier
                                          ? AppColors.textDark
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Username / Email Field
                  const Text(
                    'Staff Email or Username',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _usernameController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'e.g. driver@tropicalgyros.com',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Staff username/email is required';
                      }
                      if (!val.contains('@') && val.trim().length < 3) {
                        return 'Enter a valid staff identifier';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Password is required';
                      }
                      if (val.trim().length < 4) {
                        return 'Password must be at least 4 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  PrimaryButton(
                    text: 'Sign In (Demo)',
                    icon: Icons.login_rounded,
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 20),

                  // Demo Shortcuts
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 8),
                  const Text(
                    'Quick Demo Autofill:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _autofillDriver,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Driver Preset',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _autofillCashier,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cashier Preset',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
