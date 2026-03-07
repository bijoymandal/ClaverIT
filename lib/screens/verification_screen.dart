import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:claverit/widgets/auth_stepper.dart';
import '../models/registration_data.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import 'dashboard_screen.dart';
import 'registration_step1_screen.dart';

enum VerificationType { phone, aadhaar }

class VerificationScreen extends StatefulWidget {
  final RegistrationData registrationData;
  final VerificationType verificationType;
  final bool isLoginFlow;
  final bool sendOtpOnOpen;

  const VerificationScreen({
    super.key,
    required this.registrationData,
    required this.verificationType,
    this.isLoginFlow = false,
    this.sendOtpOnOpen = false,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  int _resendCountdown = 45;
  Timer? _resendTimer;
  bool _canResend = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    if (widget.sendOtpOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestPhoneOtp();
      });
    }
  }

  void _startTimer() {
    setState(() {
      _resendCountdown = 45;
      _canResend = false;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        setState(() => _canResend = true);
        timer.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  Future<void> _requestPhoneOtp({bool showErrorSnack = true}) async {
    final phone = widget.registrationData.phoneNumber ?? '';
    if (phone.isEmpty) return;

    if (mounted) {
      setState(() => _isResending = true);
    }

    try {
      await _authService.sendPhoneOtp(phone);
      if (!mounted) return;
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() => _canResend = true);
      if (showErrorSnack) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send OTP: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  // Dummy focus nodes for OTP fields
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _readableError(Object e) {
    final raw = e.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }
    return raw;
  }

  Future<void> _verifyAndNavigate(String otp) async {
    setState(() => _isLoading = true);

    try {
      if (widget.verificationType == VerificationType.phone) {
        final phone = widget.registrationData.phoneNumber ?? '';
        final result = await _authService.verifyPhoneOtp(phone, otp);

        if (!mounted) return;

        // Registration flow requirement: always continue to Aadhaar page
        // immediately after successful phone OTP verification.
        if (!widget.isLoginFlow) {
          widget.registrationData.phoneOtp = otp;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VerificationScreen(
                registrationData: widget.registrationData,
                verificationType: VerificationType.aadhaar,
                sendOtpOnOpen: true,
              ),
            ),
          );
          return;
        }

        // Login flow handling:
        // - If server returned a valid token (successful login), go to dashboard.
        // - If server indicates new/unregistered user (e.g., 401/account-not-found),
        //   redirect to signup (PersonalDetailsScreen).
        if (result.hasToken && !result.isNewUser) {
          await Provider.of<UserProvider>(
            context,
            listen: false,
          ).loadUserData();
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          );
        } else if (result.isNewUser) {
          // Redirect unregistered users to signup flow (personal details)
          widget.registrationData.phoneOtp = otp;
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => PersonalDetailsScreen(
                registrationData: widget.registrationData,
              ),
            ),
            (route) => false,
          );
        } else {
          // Fallback: proceed to Aadhaar verification for registration flows
          widget.registrationData.phoneOtp = otp;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VerificationScreen(
                registrationData: widget.registrationData,
                verificationType: VerificationType.aadhaar,
                sendOtpOnOpen: true,
              ),
            ),
          );
        }
      } else {
        // Sanitize gender for backend strict enum validation
        String rawGender = widget.registrationData.gender ?? '';
        String normalizedGender = rawGender.trim().toLowerCase();

        // Ensure it exactly matches what a typical backend expects
        if (normalizedGender != 'male' &&
            normalizedGender != 'female' &&
            normalizedGender != 'other') {
          normalizedGender = 'other'; // Absolute strict fallback
        }

        await _authService.signupUser(
          fullName: widget.registrationData.fullName ?? '',
          email: widget.registrationData.email ?? '',
          dateOfBirth: widget.registrationData.dobIso ?? '',
          gender: normalizedGender,
          phone: widget.registrationData.phoneNumber ?? '',
          otp: otp,
          street: widget.registrationData.streetAddress ?? '',
          city: widget.registrationData.city ?? '',
          state: widget.registrationData.state ?? '',
          pinCode: widget.registrationData.pinCode ?? '',
        );

        if (!mounted) return;
        await AuthService.clearAuthToken();
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (!mounted) return;

      final message = _readableError(e);
      final lower = message.toLowerCase();
      final isAadhaarStep = widget.verificationType == VerificationType.aadhaar;

      if (isAadhaarStep && lower.contains('account already exists')) {
        await AuthService.clearAuthToken();
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPhone = widget.verificationType == VerificationType.phone;
    final String title = isPhone
        ? 'Phone Verification'
        : 'Aadhaar Verification';
    final String subtitle = isPhone
        ? 'Verify Phone Number'
        : 'Aadhaar Verification';
    final String sentToLabel = isPhone
        ? 'OTP sent to'
        : 'OTP sent to Phone Number Reg With';
    final int currentStep = 2;

    String sentToValue = "";
    if (isPhone) {
      final rawPhone = widget.registrationData.phoneNumber ?? '';
      final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 10) {
        final mobile = digits.substring(digits.length - 10);
        sentToValue = "+91 ${mobile.substring(0, 5)} ${mobile.substring(5)}";
      } else {
        sentToValue = rawPhone;
      }
    } else {
      final rawPhone = widget.registrationData.phoneNumber ?? '';
      final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 4) {
        sentToValue = "XXXX XXXX XXXX ${digits.substring(digits.length - 4)}";
      } else {
        sentToValue = "XXXX XXXX XXXX";
      }
    }

    final IconData headerIcon = Icons.smartphone;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1014),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.question_mark, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter OTP to continue verification'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            AuthStepper(currentStep: currentStep, totalSteps: 3),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18191B),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(24),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E3A66),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      headerIcon,
                                      color: const Color(0xFF4A8BFF),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2B2F),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sentToLabel,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      sentToValue,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: const Text(
                                        'Change number',
                                        style: TextStyle(
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              const Text(
                                'Enter 6-digit OTP',
                                style: TextStyle(color: Color(0xFF9CA3AF)),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(6, (index) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: index == 5 ? 0 : 12,
                                    ),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 60,
                                      ),
                                      child: _buildOtpBox(index),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 16),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _canResend
                                          ? 'Didn\'t receive the OTP?'
                                          : 'Resend OTP in 00:${_resendCountdown.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _canResend && !_isResending
                                        ? () => _requestPhoneOtp()
                                        : null, // Disable button if counting down or currently resending
                                    child: _isResending
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF10B981),
                                            ),
                                          )
                                        : Text(
                                            'Resend OTP',
                                            style: TextStyle(
                                              color: _canResend
                                                  ? const Color(0xFF10B981)
                                                  : Colors.grey.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () async {
                                          final otp = _otpControllers
                                              .map((e) => e.text)
                                              .join();

                                          if (otp.length < 6) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please enter 6-digit OTP',
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          await _verifyAndNavigate(otp);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(14),
                                      ),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          'Verify OTP',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2B2F),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(14),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.security,
                                      color: Color(0xFF10B981),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Your phone number will be verified securely. We never share your personal information with third parties.',
                                        style: const TextStyle(
                                          color: Color(0xFFD1D5DB),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 40,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFF2A2B2F),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            borderSide: const BorderSide(color: Color(0xFF42536A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            borderSide: const BorderSide(color: Color(0xFF42536A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            borderSide: const BorderSide(color: Color(0xFF10B981)),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}
