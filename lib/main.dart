import 'package:ecom/providers/theme_provider.dart';
import 'package:ecom/providers/translate_provider.dart';
import 'package:ecom/screens/auth/LoginScreen.dart';
import 'package:ecom/screens/bottombar/MainScreen.dart';
import 'package:ecom/screens/onboarding/OnBoardingScreen.dart';
import 'package:ecom/service/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/product/product_list_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await StorageService.init();

  final translateProvider = TranslateProvider();
  await translateProvider.init(); // Load saved language

  runApp(Root(translateProvider: translateProvider)); // pass it here
}

class Root extends StatelessWidget {
  final TranslateProvider translateProvider;
  const Root({super.key, required this.translateProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider.value(value: translateProvider), // ✅ correct now
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeProvider>().mode;
    final locale = context.watch<TranslateProvider>().locale; // optional: use locale

    return MaterialApp(
      title: 'ShopEase Professional',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      home:  OnBoardingScreen(),
    );
  }
}
