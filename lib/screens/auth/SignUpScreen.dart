import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../bottombar/MainScreen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // Step 1: phone + OTP
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String? _fullPhone; // store completeNumber like +7xxxxxxxxxx
  bool _otpVerified = false;

  // Step 2: profile fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) t.cancel();
      if (mounted) setState(() => _secondsLeft = (_secondsLeft - 1).clamp(0, 60));
    });
  }

  Future<void> _sendOtp() async {
    final cs = Theme.of(context).colorScheme;
    // Basic client validation; server should validate too
    if ((_fullPhone ?? '').isEmpty || _phoneController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter a valid phone number', style: TextStyle(color: cs.onInverseSurface)), backgroundColor: cs.inverseSurface),
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // simulate API to send OTP
    if (!mounted) return;
    setState(() => _isLoading = false);
    _startTimer();
    _showOtpSheet();
  }

  Future<void> _verifyOtp() async {
    final cs = Theme.of(context).colorScheme;
    final code = _otpController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter the 6‑digit code', style: TextStyle(color: cs.onInverseSurface)), backgroundColor: cs.inverseSurface),
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // simulate verify
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _otpVerified = true;
    });
    Navigator.of(context).maybePop(); // close sheet
  }

  void _showOtpSheet() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 38, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(999))),
              ),
              const SizedBox(height: 16),
              Text('Verify OTP', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface)),
              const SizedBox(height: 6),
              Text('Code sent to ${_fullPhone ?? ''}', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 16),

              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: tt.headlineSmall?.copyWith(letterSpacing: 8, fontWeight: FontWeight.w700, color: cs.onSurface),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.outlineVariant)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.outlineVariant)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.primary, width: 1.4)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    _secondsLeft > 0 ? 'Resend in 0:${_secondsLeft.toString().padLeft(2, '0')}' : 'Didn’t get the code?',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _secondsLeft == 0
                        ? () {
                      _startTimer();
                      // TODO: re-send OTP via backend
                    }
                        : null,
                    child: Text(
                      'Resend',
                      style: tt.labelLarge?.copyWith(
                        color: _secondsLeft == 0 ? (isDark ? Colors.white : Colors.black) : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.black : Colors.white))
                      : Text('Verify & Continue', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: isDark ? Colors.black : Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_otpVerified) {
      await _sendOtp(); // request OTP first if not verified
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // simulate profile save
    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SimpleBottomNavScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;

    InputDecoration deco(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.5), fontWeight: FontWeight.w500),
      filled: true,
      fillColor: cs.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outline.withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 1.4)),
    ); // M3 field style [17][18]

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Sign up', style: tt.titleLarge?.copyWith(color: cs.onSurface)),
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: _CircleAction(
            icon: Icons.arrow_back,
            bg: isDark ? Colors.white : Colors.black,
            fg: isDark ? Colors.black : Colors.white,
            onTap: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction, // live validation [16]
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Create Account ✨", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: cs.onBackground)),
                const SizedBox(height: 8),
                Text("Verify number, then add name & email", style: TextStyle(fontSize: 16, color: cs.onBackground.withOpacity(0.6))),
                const SizedBox(height: 24),

                // Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Phone + country picker
                      Text("Phone Number", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(0.7))),
                      const SizedBox(height: 8),
                      IntlPhoneField(
                        controller: _phoneController,
                        initialCountryCode: 'RU', // default Russia
                        disableLengthCheck: true,
                        decoration: deco("Phone number").copyWith(
                          helperText: _otpVerified ? 'Verified' : 'You will receive a 6‑digit code',
                          helperStyle: TextStyle(color: _otpVerified ? cs.primary : cs.onSurfaceVariant),
                        ),
                        flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 8),
                        dropdownIconPosition: IconPosition.trailing,
                        dropdownTextStyle: TextStyle(color: cs.onSurface),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
                        onChanged: (p) => _fullPhone = p.completeNumber,
                        onCountryChanged: (c) {},
                        enabled: !_otpVerified, // lock after verification
                      ),

                      const SizedBox(height: 12),
                      if (!_otpVerified)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : Colors.black,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.black : Colors.white))
                                : const Text('Get OTP', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),

                      if (_otpVerified) ...[
                        const SizedBox(height: 16),
                        // Name
                        Text("Full Name", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(0.7))),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
                          decoration: deco("Enter your full name").copyWith(
                            prefixIcon: _ChipIcon(icon: Icons.person, isDark: isDark),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? "Enter your name" : null,
                        ),

                        const SizedBox(height: 16),
                        // Email
                        Text("Email Address", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(0.7))),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
                          decoration: deco("Enter your email").copyWith(
                            prefixIcon: _ChipIcon(icon: Icons.email, isDark: isDark),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return "Enter your email";
                            final email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                            return email.hasMatch(v.trim()) ? null : "Enter a valid email";
                          }, // basic email validation [16]
                        ),

                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : Colors.black,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.black : Colors.white))
                                : const Text("Create Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ", style: TextStyle(color: cs.onBackground.withOpacity(0.7), fontSize: 16)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text("Login", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Small black/white chip icon matching the brand
class _ChipIcon extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  const _ChipIcon({required this.icon, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 6,top: 4,bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: isDark ? Colors.white : Colors.black, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: isDark ? Colors.black : Colors.white, size: 18),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  const _CircleAction({required this.icon, required this.bg, required this.fg, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]),
          child: Icon(icon, color: fg, size: 20),
        ),
      ),
    );
  }
}
