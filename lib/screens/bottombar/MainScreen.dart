// lib/theme/app_theme.dart remains the same, you already provide light/dark schemes.

import 'package:ecom/screens/product_list_screen.dart';
import 'package:flutter/material.dart';

import '../chat/ChatListScreen.dart';
import 'HomeScreen.dart';
import 'ProfileScreen.dart';

class SimpleBottomNavScreen extends StatefulWidget {
  const SimpleBottomNavScreen({super.key});

  @override
  State<SimpleBottomNavScreen> createState() => _SimpleBottomNavScreenState();
}

class _SimpleBottomNavScreenState extends State<SimpleBottomNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens =  [
    HomeScreen(),
    ProductListScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: _screens[_currentIndex],
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  index: 0,
                  currentIndex: _currentIndex,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  onTap: _onTap,
                ),
                _NavItem(
                  index: 1,
                  currentIndex: _currentIndex,
                  icon: Icons.shopping_cart_outlined,
                  label: 'Shop',
                  onTap: _onTap,
                ),
                _NavItem(
                  index: 2,
                  currentIndex: _currentIndex,
                  icon: Icons.chat_outlined,
                  label: 'Chat',
                  onTap: _onTap,
                ),
                _NavItem(
                  index: 3,
                  currentIndex: _currentIndex,
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  onTap: _onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int i) => setState(() => _currentIndex = i);
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.onTap,
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
              child: Icon(
                icon,
                size: 24,
                color: selected ? iconSelected : iconUnselected,
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
