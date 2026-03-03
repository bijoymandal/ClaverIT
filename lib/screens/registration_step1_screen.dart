import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pro_dialer/widgets/auth_stepper.dart';
import '../models/registration_data.dart';
import '../services/auth_service.dart';
import 'verification_screen.dart';

class PersonalDetailsScreen extends StatefulWidget {
  final RegistrationData registrationData;

  const PersonalDetailsScreen({super.key, required this.registrationData});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  late TextEditingController _phoneController;
  late TextEditingController _aadhaarController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _pinCodeController;

  String? _selectedGender;
  String? _selectedState;
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _states = const [
    'Andhra Pradesh',
    'Telangana',
    'Karnataka',
    'Tamil Nadu',
    'Maharashtra',
    'Kerala',
    'Delhi',
    'Gujarat',
    'West Bengal',
    'Uttar Pradesh',
  ];

  bool _isSubmitting = false;
  bool _isSendingPhoneOtp = false;
  bool _isPhoneOtpSent = false;
  PlatformFile? _aadhaarFile;
  bool _hasReadTerms = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.registrationData.fullName,
    );
    _emailController = TextEditingController(
      text: widget.registrationData.email,
    );
    _dobController = TextEditingController(
      text: widget.registrationData.dobIso != null
          ? DateFormat(
              'MM/dd/yyyy',
            ).format(DateTime.parse(widget.registrationData.dobIso!))
          : '',
    );
    _phoneController = TextEditingController(
      text: widget.registrationData.phoneNumber,
    );
    _aadhaarController = TextEditingController(
      text: widget.registrationData.aadhaarNumber,
    );
    _streetController = TextEditingController(
      text: widget.registrationData.streetAddress,
    );
    _cityController = TextEditingController(text: widget.registrationData.city);
    _pinCodeController = TextEditingController(
      text: widget.registrationData.pinCode,
    );
    _selectedGender = widget.registrationData.gender;
    _selectedState = widget.registrationData.state;
    _isPhoneOtpSent = false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _aadhaarController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.registrationData.dobIso != null
          ? DateTime.parse(widget.registrationData.dobIso!)
          : DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              onPrimary: Colors.black,
              surface: Color(0xFF1C1C1E),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1C1C1E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        widget.registrationData.dobIso = picked.toIso8601String();
        _dobController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Future<void> _sendPhoneOtp() async {
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid 10-digit mobile number')),
      );
      return;
    }

    setState(() => _isSendingPhoneOtp = true);
    try {
      await _authService.sendPhoneOtp(phone);
      widget.registrationData.phoneNumber = phone;
      widget.registrationData.phoneOtp = null;
      setState(() => _isPhoneOtpSent = true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent to your phone number')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSendingPhoneOtp = false);
    }
  }

  Future<void> _pickAadhaarFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      const maxSizeBytes = 5 * 1024 * 1024;
      if (file.size > maxSizeBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File too large. Max size is 5MB.')),
        );
        return;
      }

      setState(() => _aadhaarFile = file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick file: $e')));
    }
  }

  Future<void> _showTermsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text(
          'Terms and Conditions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'By continuing, you agree to provide accurate details for verification. '
            'Your personal and Aadhaar information is used only for account verification and compliance. '
            'Submitting false information may lead to account suspension.',
            style: TextStyle(color: Colors.grey, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _hasReadTerms = true);
            },
            child: const Text(
              'I Have Read',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPrivacyDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'We collect only data required for account creation and legal verification. '
            'Uploaded documents are handled securely and are not shared with third parties without consent, '
            'except where required by law.',
            style: TextStyle(color: Colors.grey, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGender == null || _selectedGender!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a gender')));
      return;
    }

    if (_selectedState == null || _selectedState!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select state')));
      return;
    }

    if (!RegExp(r'^[0-9]{12}$').hasMatch(_aadhaarController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid 12-digit Aadhaar number')),
      );
      return;
    }

    if (_aadhaarFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload Aadhaar card image')),
      );
      return;
    }

    if (!_hasReadTerms || !_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please read and accept terms to continue'),
        ),
      );
      return;
    }

    widget.registrationData.fullName = _nameController.text.trim();
    widget.registrationData.email = _emailController.text.trim();
    widget.registrationData.phoneNumber = _phoneController.text.trim();
    widget.registrationData.phoneOtp = null;
    widget.registrationData.gender = _selectedGender;
    widget.registrationData.aadhaarNumber = _aadhaarController.text.trim();
    widget.registrationData.streetAddress = _streetController.text.trim();
    widget.registrationData.city = _cityController.text.trim();
    widget.registrationData.state = _selectedState;
    widget.registrationData.pinCode = _pinCodeController.text.trim();

    setState(() => _isSubmitting = true);
    try {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VerificationScreen(
            registrationData: widget.registrationData,
            verificationType: VerificationType.phone,
            sendOtpOnOpen: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false),
        ),
        title: const Text(
          'Register',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: _showTermsDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const AuthStepper(currentStep: 1, totalSteps: 3),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildPersonalInformationSection(),
                          const SizedBox(height: 16),
                          _buildPhoneSection(),
                          const SizedBox(height: 16),
                          _buildKycSection(),
                          const SizedBox(height: 16),
                          _buildAddressSection(),
                          const SizedBox(height: 16),
                          _buildTermsSection(),
                          const SizedBox(height: 24),
                          _buildCompleteButton(),
                          const SizedBox(height: 20),
                          _buildSignInText(),
                          const SizedBox(height: 24),
                        ],
                      ),
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

  Widget _buildPersonalInformationSection() {
    return _buildSectionContainer(
      icon: Icons.person,
      title: 'Personal Information',
      color: const Color(0xFF10B981),
      children: [
        _buildLabel('Full Name'),
        _buildTextField(
          controller: _nameController,
          hint: 'Enter your full name',
          validator: (value) =>
              value == null || value.isEmpty ? 'Please enter your name' : null,
        ),
        const SizedBox(height: 16),
        _buildLabel('Email Address'),
        _buildTextField(
          controller: _emailController,
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Please enter your email';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildLabel('Date of Birth'),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: AbsorbPointer(
            child: _buildTextField(
              controller: _dobController,
              hint: 'mm/dd/yyyy',
              suffixIcon: Icons.calendar_today,
              validator: (value) => value == null || value.isEmpty
                  ? 'Please select your DOB'
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('Gender'),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          dropdownColor: const Color(0xFF1C1C1E),
          iconEnabledColor: Colors.grey,
          decoration: _inputDecoration('Select Gender'),
          items: _genders
              .map(
                (gender) => DropdownMenuItem<String>(
                  value: gender,
                  child: Text(
                    gender,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedGender = value),
          validator: (value) =>
              value == null || value.isEmpty ? 'Select gender' : null,
        ),
      ],
    );
  }

  Widget _buildPhoneSection() {
    return _buildSectionContainer(
      icon: Icons.phone,
      title: 'Phone Verification',
      color: Colors.blue,
      children: [
        _buildLabel('Mobile Number'),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: const Text('+91', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: _phoneController,
                hint: 'Enter mobile number',
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) {
                  if (_isPhoneOtpSent) {
                    setState(() => _isPhoneOtpSent = false);
                  }
                  widget.registrationData.phoneOtp = null;
                },
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Enter mobile number';
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value))
                    return 'Enter valid 10-digit number';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSendingPhoneOtp ? null : _sendPhoneOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              disabledBackgroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            child: _isSendingPhoneOtp
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isPhoneOtpSent ? 'OTP Sent' : 'Send OTP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildKycSection() {
    return _buildSectionContainer(
      icon: Icons.badge,
      title: 'KYC Verification',
      color: Colors.orange,
      children: [
        _buildLabel('Aadhaar Number'),
        _buildTextField(
          controller: _aadhaarController,
          hint: 'Enter 12-digit Aadhaar number',
          keyboardType: TextInputType.number,
          maxLength: 12,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Please enter Aadhaar number';
            if (!RegExp(r'^[0-9]{12}$').hasMatch(value))
              return 'Enter valid 12-digit Aadhaar';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildLabel('Upload Aadhaar Card'),
        InkWell(
          onTap: _pickAadhaarFile,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_upload, color: Colors.grey, size: 32),
                const SizedBox(height: 8),
                Text(
                  _aadhaarFile == null
                      ? 'Tap to upload Aadhaar card image'
                      : _aadhaarFile!.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                const Text(
                  'JPG, PNG up to 5MB',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your Aadhaar information will be securely encrypted and used only for identity verification as per government guidelines.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return _buildSectionContainer(
      icon: Icons.location_on,
      title: 'Address Information',
      color: Colors.purple,
      children: [
        _buildLabel('Street Address'),
        _buildTextField(
          controller: _streetController,
          hint: 'Enter street address',
          validator: (value) =>
              value == null || value.isEmpty ? 'Enter street address' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('City'),
                  _buildTextField(
                    controller: _cityController,
                    hint: 'City',
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter city' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('PIN Code'),
                  _buildTextField(
                    controller: _pinCodeController,
                    hint: 'PIN Code',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Enter PIN code';
                      if (!RegExp(r'^[0-9]{6}$').hasMatch(value))
                        return 'Enter valid 6-digit PIN';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildLabel('State'),
        DropdownButtonFormField<String>(
          initialValue: _selectedState,
          dropdownColor: const Color(0xFF1C1C1E),
          iconEnabledColor: Colors.grey,
          decoration: _inputDecoration('Select State'),
          items: _states
              .map(
                (state) => DropdownMenuItem<String>(
                  value: state,
                  child: Text(
                    state,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedState = value),
          validator: (value) =>
              value == null || value.isEmpty ? 'Select state' : null,
        ),
      ],
    );
  }

  Widget _buildTermsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _agreedToTerms,
            onChanged: (value) {
              if (!_hasReadTerms) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please read Terms and Conditions first'),
                  ),
                );
                return;
              }
              setState(() => _agreedToTerms = value ?? false);
            },
            activeColor: const Color(0xFF10B981),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.grey, height: 1.4),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms & Conditions',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = _showTermsDialog,
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = _showPrivacyDialog,
                    ),
                    const TextSpan(
                      text:
                          '. I consent to the collection and processing of my personal data for account verification.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _completeRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Complete Registration',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
      ),
    );
  }

  Widget _buildSignInText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(color: Colors.grey),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          },
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? suffixIcon,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(hint, suffixIcon: suffixIcon),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF1C1C1E),
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Colors.grey.shade800),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Colors.grey.shade800),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Color(0xFF10B981)),
      ),
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, color: Colors.grey)
          : null,
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 14),
      ),
    );
  }

  Widget _buildSectionContainer({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
