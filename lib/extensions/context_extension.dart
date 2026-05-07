import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_handler.dart';


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import '../providers/translate_provider.dart';

extension TranslateX on BuildContext {
  String tr(String key) {
    return watch<TranslateProvider>().t(key);
  }

  String trRead(String key) {
    return read<TranslateProvider>().t(key);
  }
}