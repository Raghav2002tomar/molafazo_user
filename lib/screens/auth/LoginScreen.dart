import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart' show DeviceInfoPlugin;
import 'package:ecom/extensions/context_extension.dart';
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
import '../../services/meta_analytics_service.dart';
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
  int _phoneLength = 0;
  final ValueNotifier<int> _otpSeconds = ValueNotifier<int>(60);

  @override
  void dispose() {
    _timer?.cancel();
    _otpSeconds.dispose();
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

  void _startTimer() {
    _timer?.cancel();

    _secondsLeft = 60;
    _otpSeconds.value = 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        _otpSeconds.value = 0;
      } else {
        _secondsLeft--;
        _otpSeconds.value = _secondsLeft;
      }
    });
  }

  Future<void> _resendOtp(VoidCallback refreshSheet) async {
    if (_rawPhoneNumber.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        await AuthStorage.saveFcmToken(token);
      }

      final deviceId = await getDeviceId();
      final deviceType = await getDeviceType();

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
        _otpController.clear();

        ApiService.isBebugmode ? _showOtpToast(data['data']['otp'].toString()): null;

        setState(() => _isLoading = false);

        _startTimer();
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

  Future<void> _requestOtp() async {
    if (_rawPhoneNumber.isEmpty || _rawPhoneNumber.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('hint_enter_valid_phone_number'))),
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
        ApiService.isBebugmode ? _showOtpToast(data['data']['otp'].toString()): null;

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
                      "${context.tr('txt_otp')}: $otp",
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
    // final fcmToken = await AuthStorage.getFcmToken();
    final deviceId = await getDeviceId();
    final deviceType = await getDeviceType();
    if (code.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('txt_hint_enter_otp'))));
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
          "device_type": deviceType,
          "device_id": deviceId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        _apiToken = data['data']['api_token'];

        await AuthStorage.saveLogin(_apiToken!);

        // Meta Ads: login + first-time registration (no PII)
        unawaited(MetaAnalyticsService.instance.logLogin());
        unawaited(MetaAnalyticsService.instance.logRegistration());

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

      // User can't accidentally close OTP sheet
      isDismissible: false,
      enableDrag: false,

      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Padding(
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

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "",
                            style: tt.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '${context.tr('txt_code_sent_to')} ${_phoneController.text}',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 18),

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
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                      onChanged: (_) {
                        setSheetState(() {});
                      },
                      onSubmitted: (_) {
                        _verifyOtpAndLogin();
                      },
                    ),

                    const SizedBox(height: 14),

                    ValueListenableBuilder<int>(
                      valueListenable: _otpSeconds,
                      builder: (context, seconds, _) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cs.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                seconds > 0
                                    ? Icons.timer_outlined
                                    : Icons.refresh_rounded,
                                size: 18,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  seconds > 0
                                      ? '${context.tr('txt_resend_to')} ${seconds.toString().padLeft(2, '0')}s'
                                      : context.tr('txt_did_no_get'),
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: seconds == 0 && !_isLoading
                                    ? () {
                                        _resendOtp(() {});
                                      }
                                    : null,
                                child: _isLoading && seconds == 0
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        context.tr('txt_resend'),
                                        style: tt.labelLarge?.copyWith(
                                          color: seconds == 0
                                              ? (isDark
                                                    ? Colors.white
                                                    : Colors.black)
                                              : cs.onSurfaceVariant,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),

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
                                context.tr('txt_verify_continue'),
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
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: cs.background,
        appBar: AppBar(),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/logo_bg_remove.png",
                    height: 150,
                  ),
                ],
              ),
              // Welcome Header
              // Text(
              //   context.tr('txt_welcome_back'),
              //   style: TextStyle(
              //     fontSize: 28,
              //     fontWeight: FontWeight.w800,
              //     color: cs.onBackground,
              //   ),
              // ),
              // const SizedBox(height: 8),
              // Text(
              //   context.tr('txt_login_with_number'),
              //   style: TextStyle(
              //     fontSize: 16,
              //     color: cs.onBackground.withOpacity(0.6),
              //   ),
              // ),

              // const SizedBox(height: 40),

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
                    // Text(
                    //   context.tr('txt_phone_number'),
                    //   style: TextStyle(
                    //     fontSize: 14,
                    //     fontWeight: FontWeight.w600,
                    //     color: cs.onSurface.withOpacity(0.7),
                    //   ),
                    // ),
                    // const SizedBox(height: 12),

                    // Phone Input

                    // Phone Input with country code (default Russia)
                    IntlPhoneField(
                      controller: _phoneController,
                      initialCountryCode: 'TJ',

                      disableLengthCheck:
                          true, // keep this if you want custom validation
                      inputFormatters: ApiService.isBebugmode
                          ? null
                          : [
                        LengthLimitingTextInputFormatter(9),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
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
                          minLength: ApiService.isBebugmode == true ? 10 : 9,
                          maxLength: ApiService.isBebugmode == true ? 10 : 9,
                        ),
                        // Country(
                        //   name: "Russia",
                        //   nameTranslations: {"en": "Russia", "ru": "Россия"},
                        //   flag: "🇷🇺",
                        //   code: "RU",
                        //   dialCode: "7",
                        //   minLength: ApiService.isBebugmode == true? 10: 9,
                        //   maxLength: ApiService.isBebugmode == true? 10: 9,
                        // ),
                      ],

                      showDropdownIcon: false,

                      decoration: InputDecoration(
                        // labelText: context.tr('txt_phone_number'),
                        // hintText: context.tr('txt_phone_number'),
                        filled: true,
                        fillColor: cs.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),

                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              '$_phoneLength/9',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _phoneLength == 9
                                    ? Colors.black
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),

                      //
                      // /// ✅ VALIDATION
                      // validator: (phone) {
                      //   if (phone == null || phone.number.isEmpty) {
                      //     return context.tr('hint_phone_number_required');
                      //   }
                      //
                      //   final min = ApiService.isBebugmode ? 10 : 9;
                      //   final max = ApiService.isBebugmode ? 10 : 9;
                      //
                      //   if (phone.number.length < min || phone.number.length > max) {
                      //     return 'Enter $min digit phone number';
                      //   }
                      //
                      //   return null;
                      // },
                      onChanged: (phone) {
                        setState(() {
                          _rawPhoneNumber = phone.number;
                          _phoneLength = phone.number.length;
                        });
                      },
                    ),

                    const SizedBox(height: 36),

                    // Login Button -> requests OTP then shows sheet
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _requestOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white
                              : Colors.black,
                          foregroundColor: isDark
                              ? Colors.black
                              : Colors.white,
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
                            : Text(
                                context.tr('txt_get_otp'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // // Or continue text
                    // Row(
                    //   children: [
                    //     Expanded(child: Divider(color: cs.outlineVariant)),
                    //     Padding(
                    //       padding: const EdgeInsets.symmetric(horizontal: 12),
                    //       child: Text(
                    //         context.tr('txt_or'),
                    //         style: TextStyle(color: cs.onSurfaceVariant),
                    //       ),
                    //     ),
                    //     Expanded(child: Divider(color: cs.outlineVariant)),
                    //   ],
                    // ),
                    //
                    // const SizedBox(height: 12),
                    //
                    // // Skip Button
                    // SizedBox(
                    //   width: double.infinity,
                    //   height: 48,
                    //   child: OutlinedButton(
                    //     onPressed: () {
                    //       Navigator.pushAndRemoveUntil(
                    //         context,
                    //         MaterialPageRoute(
                    //           builder: (_) => const SimpleBottomNavScreen(),
                    //         ),
                    //             (route) => false,
                    //
                    //       );
                    //     },
                    //     style: OutlinedButton.styleFrom(
                    //       side: BorderSide(color: cs.outlineVariant),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(14),
                    //       ),
                    //     ),
                    //     child: Text(
                    //       context.tr('txt_skip_for_now'),
                    //       style: TextStyle(
                    //         color: cs.onSurface.withOpacity(0.8),
                    //         fontWeight: FontWeight.w600,
                    //       ),
                    //     ),
                    //   ),
                    // ),
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
