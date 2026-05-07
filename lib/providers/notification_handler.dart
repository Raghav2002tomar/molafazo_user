import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../service/translations.dart';

class TranslateProvider with ChangeNotifier {
  static const _boxName = 'settings';
  static const _localeKey = 'locale';

  String _locale = 'ru'; // ✅ default Russian

  String get locale => _locale;

  Future<void> init() async {
    final box = await Hive.openBox(_boxName);

    final savedLocale = box.get(_localeKey);

    if (savedLocale != null) {
      // ✅ normalize old values (important fix)
      _locale = _normalizeLang(savedLocale);
    } else {
      // ✅ first time install → set Russian
      _locale = 'ru';
      await box.put(_localeKey, 'ru');
    }

    notifyListeners();
  }

  Future<void> setLocale(String langCode) async {
    final box = await Hive.openBox(_boxName);

    // ✅ normalize before saving
    _locale = _normalizeLang(langCode);

    await box.put(_localeKey, _locale);
    notifyListeners();
  }

  /// 🔥 IMPORTANT: fix tj → tg here
  String _normalizeLang(String lang) {
    final lower = lang.toLowerCase();

    if (lower == 'tj') return 'tg'; // 👈 main fix

    return lower;
  }

  String t(String key) {
    final lang = _normalizeLang(_locale);

    return translations[lang]?[key] ??
        translations['ru']?[key] ?? // fallback Russian
        key;
  }
}