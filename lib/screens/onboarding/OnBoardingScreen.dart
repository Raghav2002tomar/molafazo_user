import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/deep_link_service.dart';
import '../auth/LoginScreen.dart';
import '../bottombar/MainScreen.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({Key? key}) : super(key: key);

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  bool isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 2));

    final isLoggedIn = await AuthStorage.isLoggedIn();
    if (!mounted) return;

    Navigator.push(context, MaterialPageRoute(builder: (context)=>SimpleBottomNavScreen()));

    // Open product detail if app was launched from a shared link
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.instance.flushPending();
    });

    // if (!mounted) return;

    // Navigator.pushAndRemoveUntil(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) =>
    //     isLoggedIn ? const SimpleBottomNavScreen() : const AuthScreen(),
    //   ),
    //       (route) => false,
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          "assets/images/logo_bg_remove.png",
          height: 250,

          // 🔥 Detect when image is ready
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              // Image loaded → show full UI
              if (!isImageLoaded) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    isImageLoaded = true;
                  });
                });
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  child,
                  // const SizedBox(height: 18),
                  const Text(
                    "inBozor",
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.black,
                    ),
                  ),
                ],
              );
            }

            // ⛔ While loading → show NOTHING (white screen)
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}