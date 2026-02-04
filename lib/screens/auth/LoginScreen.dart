import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../bottombar/MainScreen.dart';
import 'SignUpScreen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String _rawPhoneNumber = ''; // without country code
  int? _userIdFromOtp;
  String? _apiToken;
  // OTP state
  bool _showOtp = false;
  int _secondsLeft = 60;
  Timer? _timer;

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (_rawPhoneNumber.isEmpty || _rawPhoneNumber.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/customer/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "phone_number": _rawPhoneNumber,
          "device_type": "android",
          "device_id": "abc123",
          "fcm_token": "123456",
        }),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        _userIdFromOtp = data['data']['user_id'];

        setState(() {
          _isLoading = false;
          _showOtp = true;
        });

        _startTimer();
        _showOtpSheet();
      } else {
        throw data['message'];
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }



  Future<void> _verifyOtpAndLogin() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/customer/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "phone_number": _rawPhoneNumber,
          "otp": code,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        _apiToken = data['data']['api_token'];

        await AuthStorage.saveLogin(_apiToken!);

        // TODO: Save token securely (SharedPreferences / SecureStorage)

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SimpleBottomNavScreen()),
        );
      } else {
        throw data['message'];
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showOtpSheet() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Verify OTP', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface)),
              const SizedBox(height: 6),
              Text('Code sent to ${_phoneController.text}', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 16),

              // Option A: Native 6 TextFields in one with inputFormatters
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cs.primary, width: 1.4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              // Option B: Pinput (uncomment if using package)
              /*
              Pinput(
                controller: _otpController,
                length: 6,
                defaultPinTheme: PinTheme(
                  width: 48,
                  height: 56,
                  textStyle: tt.titleLarge?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                ),
                focusedPinTheme: PinTheme(
                  width: 48,
                  height: 56,
                  textStyle: tt.titleLarge?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primary, width: 1.5),
                  ),
                ),
                onCompleted: (v) => _verifyOtpAndLogin(),
              ),
              */

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
                      // TODO: re-request code from backend
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
                  onPressed: _isLoading ? null : _verifyOtpAndLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.black : Colors.white),
                  )
                      : Text('Verify & Continue', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700,color: isDark ? Colors.black : Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Welcome Header
              Text(
                "Welcome Back 👋",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: cs.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Login with your phone number to continue",
                style: TextStyle(
                  fontSize: 16,
                  color: cs.onBackground.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 40),

              // Login Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Phone Number",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Phone Input

                    // Phone Input with country code (default Russia)
                  IntlPhoneField(
                    controller: _phoneController,
                    initialCountryCode: 'TJ', // Tajikistan (+992)
                    disableLengthCheck: true,
                    decoration: InputDecoration(
                      labelText: 'Phone number',
                      hintText: '900 12 34 56',
                      filled: true,
                      fillColor: cs.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (phone) {
                      // 🔥 ONLY NATIONAL NUMBER (NO +992)
                      _rawPhoneNumber = phone.number;
                    },
                  ),



                    const SizedBox(height: 24),

                    // Login Button -> requests OTP then shows sheet
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _requestOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(color: isDark ? Colors.black : Colors.white, strokeWidth: 2),
                        )
                            : const Text("Get OTP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Or continue text
                    Row(
                      children: [
                        Expanded(child: Divider(color: cs.outlineVariant)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text("or", style: TextStyle(color: cs.onSurfaceVariant)),
                        ),
                        Expanded(child: Divider(color: cs.outlineVariant)),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Skip Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SimpleBottomNavScreen()));
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: cs.outlineVariant),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text("Skip for now →", style: TextStyle(color: cs.onSurface.withOpacity(0.8), fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
