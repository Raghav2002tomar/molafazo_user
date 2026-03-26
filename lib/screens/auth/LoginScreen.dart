import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart' show DeviceInfoPlugin;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../main.dart';
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

  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Get device ID
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;

        // ANDROID ID (Best unique ID)
        return androidInfo.id ?? androidInfo.model ?? "unknown_android";
      }

      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? "unknown_ios";
      }

      return "unknown_device";
    } catch (e) {
      return "unknown_device";
    }
  }

  /// Get device type
  static Future<String> getDeviceType() async {
    if (Platform.isAndroid) return "android";
    if (Platform.isIOS) return "ios";
    return "unknown";
  }

  /// Optional: Get full device name
  static Future<String> getDeviceName() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return "${info.brand} ${info.model}";
    }

    if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return info.name;
    }

    return "unknown";
  }

  Future<void> _requestOtp() async {
    if (_rawPhoneNumber.isEmpty || _rawPhoneNumber.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final token = await FirebaseMessaging.instance.getToken();
    await AuthStorage.saveFcmToken(token!);
    await AuthStorage.saveMobile(_rawPhoneNumber);

    // final fcmToken = await AuthStorage.getFcmToken();
    final deviceId = await getDeviceId();
    final deviceType = await getDeviceType();

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/customer/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "phone_number": _rawPhoneNumber,
          "device_type": deviceType,
          "device_id": deviceId,
          "fcm_token": token,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        _showOtpToast(data['data']['otp'].toString());

        setState(() {
          _isLoading = false;
          _showOtp = true;
        });

        _startTimer();

        // ⏳ Delay so snackbar shows above everything
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            _showOtpSheet();
          }
        });
      } else {
        throw data['message'];
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showOtpToast(String otp) {
    // if (kReleaseMode) return; // 🔐 dev only

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "OTP: $otp",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    // ⏳ Auto remove after 4 seconds
    Future.delayed(const Duration(seconds: 15), () {
      entry.remove();
    });
  }

  Future<void> _verifyOtpAndLogin() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter 6-digit OTP')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/customer/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"phone_number": _rawPhoneNumber, "otp": code}),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        _apiToken = data['data']['api_token'];

        await AuthStorage.saveLogin(_apiToken!);

        // TODO: Save token securely (SharedPreferences / SecureStorage)

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SimpleBottomNavScreen()),
              (route) => false,

        );
      } else {
        throw data['message'];
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
              Text(
                'Verify OTP',
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Code sent to ${_phoneController.text}',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),

              // Option A: Native 6 TextFields in one with inputFormatters
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: tt.headlineSmall?.copyWith(
                  letterSpacing: 8,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
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
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _secondsLeft > 0
                        ? 'Resend in 0:${_secondsLeft.toString().padLeft(2, '0')}'
                        : 'Didn’t get the code?',
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
                        color: _secondsLeft == 0
                            ? (isDark ? Colors.white : Colors.black)
                            : cs.onSurfaceVariant,
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        )
                      : Text(
                          'Verify & Continue',
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
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
                      initialCountryCode: 'TJ',
                      disableLengthCheck: true,

                      // 🔒 HARD LOCK COUNTRY (ONLY TAJIKISTAN)
                      // 🔒 HARD LOCK COUNTRIES (TAJIKISTAN + RUSSIA)
                      countries: const [
                        Country(
                          name: "Tajikistan",
                          nameTranslations: {
                            "en": "Tajikistan",
                            "ru": "Таджикистан",
                          },
                          flag: "🇹🇯",
                          code: "TJ",
                          dialCode: "992",
                          minLength: 9,
                          maxLength: 9,
                        ),
                        Country(
                          name: "Russia",
                          nameTranslations: {"en": "Russia", "ru": "Россия"},
                          flag: "🇷🇺",
                          code: "RU",
                          dialCode: "7",
                          minLength: 10,
                          maxLength: 10,
                        ),
                      ],

                      showDropdownIcon: false,

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
                        _rawPhoneNumber = phone.number; // national number only
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: isDark ? Colors.black : Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Get OTP",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Or continue text
                    Row(
                      children: [
                        Expanded(child: Divider(color: cs.outlineVariant)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "or",
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
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
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SimpleBottomNavScreen(),
                            ),
                                (route) => false,

                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: cs.outlineVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          "Skip for now →",
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
