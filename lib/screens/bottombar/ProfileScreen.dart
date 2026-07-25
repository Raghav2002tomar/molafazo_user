import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:ecom/extensions/context_extension.dart';
import 'package:ecom/screens/auth/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_handler.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../address/address_list_screen.dart';
import '../cart/controller/cart_services.dart';
import '../cart/order_list_screen.dart';
import '../profile/FAQ_Screen.dart';
import '../profile/SettingScreen.dart';
import '../profile/controller/profile_service.dart';
import '../profile/controller/user_storage.dart';
import '../profile/favorite_products_screen.dart';
import '../profile/model/PolicyContentScreen.dart';
import '../profile/model/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {

    final result = await CartService.getCartList();

    if (result['requiresLogin'] == true) {
      // User not logged in, redirect to login
      if (mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AuthScreen())
        );
      }
      return;
    }


    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final user = await ProfileService.fetchProfile();
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
      });
    } catch (_) {
      final localUser = await UserStorage.getUser();
      if (!mounted) return;
      setState(() {
        _user = localUser;
        _loading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadProfile();
  }

  void _requireLogin(VoidCallback onAllowed) {
    if (_user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AuthScreen()),
      );
    } else {
      onAllowed();
    }
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
  Future<void> _changeLanguage(String lang) async {
    final deviceId = await getDeviceId();
    final deviceType = await getDeviceType();

    try {
      final token = await AuthStorage.getToken();

      // Always normalize Tajik to tg internally
      final normalizedLang = lang.toLowerCase() == 'tj' ? 'tg' : lang.toLowerCase();

      context.read<TranslateProvider>().setLocale(normalizedLang);

      await ApiService.postFormData(
        endpoint: '/update-language',
        token: token,
        fields: {
          'device_token': deviceId,
          'device_type': deviceType,
          'language': normalizedLang,
        },
      );
    } catch (e) {
      debugPrint("Language update error: $e");
    }
  }

  String _getDisplayLanguageCode(String locale) {
    final normalized = locale.toLowerCase() == 'tj' ? 'tg' : locale.toLowerCase();

    switch (normalized) {
      case 'tg':
        return 'TJ';
      case 'ru':
        return 'RU';
      case 'en':
        return 'EN';
      default:
        return normalized.toUpperCase();
    }
  }

  Widget _buildLanguageMenu(ColorScheme cs) {
    final locale = context.watch<TranslateProvider>().locale;

    return PopupMenuButton<String>(
      onSelected: (lang) async {
        await _changeLanguage(lang);
      },
      itemBuilder: (context) =>  [
          ?ApiService.isBebugmode == true?   PopupMenuItem(
          value: 'en',
          child: Text('English'),
        ): null,
        PopupMenuItem(
          value: 'ru',
          child: Text('Русский'),
        ),
       // PopupMenuItem(
       //    value: 'tg',
       //    child: Text('Тоҷикӣ'),
       //  ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getDisplayLanguageCode(locale),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.arrow_drop_down,
            color: cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.tr('txt_profile'),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _user == null
                  ? _buildLoginCard(context, cs)
                  : _buildProfileCard(cs),

              const SizedBox(height: 24),

              _buildCard(
                cs,
                children: [
                  _buildMenuItem(
                    context,
                    cs,
                    Icons.shopping_bag_outlined,
                    context.tr('txt_my_order'),
                        () {
                      _requireLogin(() {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderListScreen(),
                          ),
                        );
                      });
                    },
                  ),
                  _buildDivider(cs),
                  _buildMenuItem(
                    context,
                    cs,
                    Icons.favorite_outline,
                    context.tr('txt_my_fav'),
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const FavoriteProductsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(cs),
                  _buildMenuItem(
                    context,
                    cs,
                    Icons.local_shipping_outlined,
                    context.tr('txt_shipping_address'),
                        () {
                      _requireLogin(() {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddressListScreen(),
                          ),
                        );
                      });
                    },
                  ),
                  // _buildDivider(cs),
                  // _buildMenuItem(
                  //   context,
                  //   cs,
                  //   Icons.credit_card_outlined,
                  //   context.tr('txt_my_card'),
                  //       () {
                  //     _requireLogin(() {
                  //       // Navigate to card screen
                  //     });
                  //   },
                  // ),
                  _buildDivider(cs),
                  _buildMenuItem(
                    context,
                    cs,
                    Icons.language,
                    context.tr('txt_language'),
                        () {},
                    trailing: _buildLanguageMenu(cs),
                    isLast: true,
                  ),               ],
              ),

              const SizedBox(height: 24),

              _buildCard(
                cs,
                children: [
                  _buildMenuItem(
                    context,
                    cs,
                    Icons.help_outline,
                    context.tr('txt_faq'),
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FAQScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(cs),
                  _buildMenuItem(
                    context,
                    cs,
                    Icons.privacy_tip_outlined,
                    context.tr('txt_privacy_policy'),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PolicyContentScreen(
                                title: context.tr('txt_privacy_policy'),
                                endpoint: '/privacy-policy',
                              ),
                            ),
                          );
                        },
                    isLast: true,
                  ),
                  _buildDivider(cs),
                  _buildMenuItem(
                    context,
                    cs,
                    Icons.privacy_tip_outlined,
                    context.tr('txt_terms_conditions'),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PolicyContentScreen(
                                title: context.tr('txt_terms_conditions'),
                                endpoint: '/terms-conditions',
                              ),
                            ),
                          );
                        },
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(ColorScheme cs, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(
      BuildContext context,
      ColorScheme cs,
      IconData icon,
      String title,
      VoidCallback onTap, {
        bool isLast = false,
        Widget? trailing,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isLast ? 16 : 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            _CircleAction(
              icon: icon,
              bg: isDark ? Colors.white : Colors.black,
              fg: isDark ? Colors.black : Colors.white,
              onTap: () {},
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      color: cs.outlineVariant,
    );
  }

  Widget _buildProfileCard(ColorScheme cs) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
        );

        if (result == true) {
          _loadProfile();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(10, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.grey.shade200,
              ),
              child: _user?.profilePhoto != null &&
                  _user!.profilePhoto!.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.network(
                  "${ApiService.ImagebaseUrl}${ApiService.profile_image_URL}${_user!.profilePhoto!}",
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person,
                    size: 32,
                    color: Colors.grey,
                  ),
                ),
              )
                  : const Icon(
                Icons.person,
                size: 32,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _user!.name.isNotEmpty
                        ? _user!.name
                        : context.tr('txt_user'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user!.mobile?.toString() ?? "0987****",
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context, ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AuthScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.black : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.lock_outline,
                color: isDark ? Colors.black : Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('txt_login_required'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('txt_access_order'),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.white70
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.white70 : cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

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
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: fg, size: 20),
        ),
      ),
    );
  }
}