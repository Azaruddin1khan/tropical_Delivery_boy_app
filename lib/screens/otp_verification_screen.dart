import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/primary_button.dart';
import '../services/api_service.dart';
import 'reset_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String? initialOtp;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.initialOtp,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _otpLength = 6;
  static const int _resendCooldownSeconds = 45;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  bool _isVerifying = false;
  bool _isResending = false;
  int _secondsRemaining = _resendCooldownSeconds;
  Timer? _timer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());

    _startTimer();

    // If an initial demo OTP was provided, prefill it after frame render
    if (widget.initialOtp != null && widget.initialOtp!.trim().length == _otpLength) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _populateOtp(widget.initialOtp!.trim());
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _resendCooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  void _populateOtp(String otp) {
    for (int i = 0; i < _otpLength && i < otp.length; i++) {
      _controllers[i].text = otp[i];
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes.last.requestFocus();
    }
    setState(() => _errorMessage = null);
  }

  String _getCombinedOtp() {
    return _controllers.map((c) => c.text.trim()).join();
  }

  void _handleOtpChanged(int index, String value) {
    setState(() => _errorMessage = null);

    // Handle paste of complete 6-digit code into any box
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= _otpLength) {
        _populateOtp(digits.substring(0, _otpLength));
        return;
      }
    }

    if (value.isNotEmpty) {
      // Move to next box
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Auto-verify if all 6 digits entered
        final code = _getCombinedOtp();
        if (code.length == _otpLength) {
          _handleVerify();
        }
      }
    }
  }

  void _handleVerify() async {
    final otp = _getCombinedOtp();
    if (otp.length < _otpLength) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit verification code.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final result = await DeliveryApiService.verifyOtp(
      email: widget.email,
      otp: otp,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code confirmed! Set your new password.'),
          backgroundColor: AppColors.limeGreenDark,
          behavior: SnackBarBehavior.floating,
        ),
      );

      final token = result['token']?.toString();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: widget.email,
            otp: otp,
            token: token,
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = result['error']?.toString() ??
            'Invalid or expired verification code. Please check and try again.';
      });
    }
  }

  void _handleResendCode() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final result = await DeliveryApiService.forgotPassword(widget.email);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (result['success'] == true) {
      _startTimer();
      // Clear previous inputs
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();

      final demoOtp = result['demoOtp']?.toString();
      final msg = demoOtp != null
          ? 'New code sent! Code: $demoOtp'
          : (result['message']?.toString() ?? 'A new verification code was sent to your email.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.limeGreenDark,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );

      if (demoOtp != null) {
        _populateOtp(demoOtp);
      }
    } else {
      setState(() {
        _errorMessage = result['error']?.toString() ?? 'Failed to resend code. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerText =
        '00:${_secondsRemaining.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Verify OTP Code',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // Animated/Highlighted Security Icon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.tropicalYellowLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.tropicalYellowDark.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_clock_rounded,
                    color: AppColors.tropicalYellowDark,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Enter Verification Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit verification code to\n'),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // Change email button
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Change email / phone'),
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.tropicalYellowDark,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Test Mode Autofill Helper Pill (if demo OTP was provided)
              if (widget.initialOtp != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.oceanBlueLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.oceanBlue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.oceanBlueDark, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Test Mode OTP: ${widget.initialOtp}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.oceanBlueDark,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _populateOtp(widget.initialOtp!),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.oceanBlueDark.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'Fill Code',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.oceanBlueDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 6-Digit Pin Input Row
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 6.0;
                  final availableWidth = constraints.maxWidth - (_otpLength - 1) * spacing;
                  final boxWidth = (availableWidth / _otpLength).clamp(36.0, 52.0);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_otpLength, (index) {
                      return SizedBox(
                        width: boxWidth,
                        height: 56,
                        child: KeyboardListener(
                          focusNode: FocusNode(),
                          onKeyEvent: (event) {
                            // Handle backspace navigation to previous box
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.backspace &&
                                _controllers[index].text.isEmpty &&
                                index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                          },
                          child: TextFormField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _controllers[index].text.isNotEmpty
                                      ? AppColors.tropicalYellowDark
                                      : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.tropicalYellowDark,
                                  width: 2.2,
                                ),
                              ),
                            ),
                            onChanged: (val) => _handleOtpChanged(index, val),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.errorRedLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.errorRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 16),

              // Verify Button
              PrimaryButton(
                text: 'Verify Code',
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isVerifying,
                variant: ButtonVariant.primary,
                width: double.infinity,
                onPressed: _handleVerify,
              ),
              const SizedBox(height: 24),

              // Resend OTP Section
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    "Didn't receive the code? ",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (_secondsRemaining > 0)
                    Text(
                      'Resend in $timerText',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.tropicalYellowDark,
                      ),
                    )
                  else
                    InkWell(
                      onTap: _isResending ? null : _handleResendCode,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: _isResending
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Resend Code',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.tropicalYellowDark,
                                  decoration: TextDecoration.underline,
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
    );
  }
}
