// lib/theme/app_theme.dart remains the same, you already provide light/dark schemes.

import 'package:ecom/extensions/context_extension.dart';
import 'package:ecom/screens/auth/LoginScreen.dart';
import 'package:ecom/screens/product/product_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/login_required_screen.dart';
import '../cart/cart_screen.dart';
import '../chat/ChatListScreen.dart';
import 'HomeScreen.dart';
import 'ProfileScreen.dart';

class SimpleBottomNavScreen extends StatefulWidget {
  final int selectedIndex;

  const SimpleBottomNavScreen({
    super.key,
    this.selectedIndex = 0,
  });

  @override
  State<SimpleBottomNavScreen> createState() =>
      _SimpleBottomNavScreenState();
}

class _SimpleBottomNavScreenState extends State<SimpleBottomNavScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  List<Widget> get _screens => [
    HomeScreen(),
    _AuthRequiredWrapper(child: CartScreen()),
    _AuthRequiredWrapper(child: ChatListScreen()),
    _AuthRequiredWrapper(child: ProfileScreen()),
  ];

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false, // phone back button disabled on this screen
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Optional: if user is not on Home tab, move to Home tab
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }

        // If already on Home tab, do nothing
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    index: 0,
                    currentIndex: _currentIndex,
                    icon: Icons.home_rounded,
                    label: context.tr('title_home'),
                    onTap: _onTap,
                  ),
                  Consumer<CartProvider>(
                    builder: (context, cart, child) {
                      return _NavItem(
                        index: 1,
                        currentIndex: _currentIndex,
                        icon: Icons.shopping_cart_outlined,
                        label: context.tr('title_cart'),
                        onTap: _onTap,
                        cartCount: cart.cartCount,
                      );
                    },
                  ),
                  _NavItem(
                    index: 2,
                    currentIndex: _currentIndex,
                    icon: Icons.chat_outlined,
                    label: context.tr('title_chat'),
                    onTap: _onTap,
                  ),
                  _NavItem(
                    index: 3,
                    currentIndex: _currentIndex,
                    icon: Icons.person_outline_rounded,
                    label: context.tr('title_profile'),
                    onTap: _onTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int i) async {
    // Home is always open
    if (i == 0) {
      setState(() => _currentIndex = i);
      return;
    }

    // Cart, Chat, Profile require login
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      setState(() => _currentIndex = i);
      return;
    }

    setState(() => _currentIndex = i);
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final ValueChanged<int> onTap;
  final int cartCount;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.onTap,
    this.cartCount = 0,

  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool selected = index == currentIndex;

    // Colors to match screenshot but adapt to theme:
    // - pillPad is the long rounded “label area” behind the icon + text.
    // - iconChip is the small black circle behind the icon.
    final Color pillPad = selected
        ? (Theme.of(context).brightness == Brightness.light
        ? Colors.grey.shade300 // light pill background like screenshot
        : cs.surfaceContainerHigh) // dim neutral in dark
        : Colors.transparent;

    final Color iconChip = selected
        ? Colors.black // small circle is pure black in both modes (per screenshot)
        : Colors.transparent;

    final Color iconSelected = Colors.white; // white icon on black chip
    final Color iconUnselected = Theme.of(context).brightness == Brightness.light
        ? Colors.black.withOpacity(0.54)
        : cs.onSurfaceVariant; // softer grey in dark

    final Color labelColor = Theme.of(context).brightness == Brightness.light
        ? Colors.black // black text on light pill
        : cs.onSurface; // readable text on dark pill

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(right: selected ? 10 : 0),
        decoration: BoxDecoration(
          color: pillPad,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular black icon chip when selected
            Container(
              decoration: BoxDecoration(
                color: iconChip,
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.all(8),
               child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            icon,
            size: 24,
            color: selected ? iconSelected : iconUnselected,
          ),

          if (cartCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  cartCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
class _AuthRequiredWrapper extends StatelessWidget {
  final Widget child;

  const _AuthRequiredWrapper({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthStorage.getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final token = snapshot.data;

        if (token == null || token.isEmpty) {
          return LoginRequiredScreen(
            showBackButton: false,
            onLogin: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>AuthScreen()));
              // Navigate to your login screen here
              // Example:
              // Navigator.pushNamed(context, '/login');
            },
          );
        }

        return child;
      },
    );
  }
}