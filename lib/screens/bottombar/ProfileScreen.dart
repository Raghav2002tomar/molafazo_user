import 'package:ecom/screens/auth/LoginScreen.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../address/address_list_screen.dart';
import '../cart/order_list_screen.dart';
import '../profile/SettingScreen.dart';
import '../profile/controller/profile_service.dart';
import '../profile/controller/user_storage.dart';
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
    try {
      final user = await ProfileService.fetchProfile();
      setState(() {
        _user = user;
        _loading = false;
      });
    } catch (_) {
      _user = await UserStorage.getUser(); // may be null
      setState(() => _loading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // leading: Container(
        //   margin: const EdgeInsets.all(8),
        //   decoration: BoxDecoration(
        //     color: cs.primary,
        //     borderRadius: BorderRadius.circular(25),
        //   ),
        //   child: Icon(
        //     Icons.arrow_back,
        //     color: cs.onPrimary,
        //     size: 20,
        //   ),
        // ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surface,

              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              onPressed: () {
                _requireLogin(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditProfileScreen()),
                  );
                });

              },
              icon: Icon(
                Icons.settings_outlined,
                color: cs.onSurface,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Profile Card
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _user == null
                  ? _buildLoginCard(context, cs)
                  : _buildProfileCard(cs),


              const SizedBox(height: 24),

              // Menu Items Card
              _buildCard(
                cs,
                children: [
                  // _buildMenuItem(
                  //   context,
                  //   cs,
                  //   Icons.person_outline,
                  //   'Personal Details',
                  //   () {},
                  // ),
                  // _buildDivider(cs),
                  _buildMenuItem(
                    context,
                    cs,
                    Icons.shopping_bag_outlined,
                    'My Order',
                        () {
                      _requireLogin(() {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OrderListScreen()),
                        );
                      });
                    },
                  ),

                  _buildDivider(cs),
                  _buildMenuItem(
                    context,
                    cs,
                    Icons.favorite_outline,
                    'My Favourites',
                    () {},
                  ),
                  _buildDivider(cs),
                  _buildMenuItem(
                    context,
                    cs,
                    Icons.local_shipping_outlined,
                    'Shipping Address',
                        () {
                      _requireLogin(() {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AddressListScreen()),
                        );
                      });
                    },
                  ),

                  _buildDivider(cs),
                  _buildMenuItem(
                    context,
                    cs,
                    Icons.credit_card_outlined,
                    'My Card',
                        () {
                      _requireLogin(() {
                        // Navigate to card screen
                      });
                    },
                  ),

                  _buildDivider(cs),
                  _buildMenuItem(
                    context,
                    cs,
                    Icons.settings_outlined,
                    'Settings',
                    () {},
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Bottom Menu Items Card
              _buildCard(
                cs,
                children: [
                  _buildMenuItem(
                    context,
                    cs,
                    Icons.help_outline,
                    'FAQs',
                    () {},
                  ),
                  _buildDivider(cs),
                  _buildMenuItem(
                    context,
                    cs,
                    Icons.privacy_tip_outlined,
                    'Privacy Policy',
                    () {},
                    isLast: true,
                  ),
                ],
              ),
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
    context,
    ColorScheme cs,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isLast = false,
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
              onTap: () => Navigator.pop(context),
            ),
            // Icon(icon, size: 24, color: cs.onSurface),
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
            Icon(Icons.arrow_forward_ios, size: 16, color: cs.onSurfaceVariant),
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
    return Container(
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
            child: _user?.profilePhoto != null && _user!.profilePhoto!.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.network(
                "${ApiService.ImagebaseUrl}${ApiService.profile_image_URL}${_user!.profilePhoto!}",
                fit: BoxFit.cover,
              ),
            )
                : const Icon(
              Icons.person,
              size: 32,
              color: Colors.grey,
            ),
          )
,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user!.name.isNotEmpty?   _user!.name: "User" ,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user!.name.isNotEmpty?  _user!.email: "user@gmail.com",
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          InkWell(onTap: (){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>EditProfileScreen()));
          }, child: Icon(Icons.arrow_forward_ios))
        ],
      ),
    );
  }
  Widget _buildLoginCard(BuildContext context, ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(onTap: (){
      Navigator.push(context, MaterialPageRoute(builder: (context)=>AuthScreen()));
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
            // Icon container
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

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Login required",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Access orders, address & profile",
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

            // Arrow
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

            // shape: BoxShape.circle,
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
