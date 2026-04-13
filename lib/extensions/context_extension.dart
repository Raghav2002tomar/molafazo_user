import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/translate_provider.dart';

extension TranslateX on BuildContext {
  String tr(String key) {
    return watch<TranslateProvider>().t(key);
  }
}