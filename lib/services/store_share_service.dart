import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../service/translations.dart';
import 'deep_link_service.dart';

class StoreShareService {
  StoreShareService._();

  /// Opens the native share sheet with a store link.
  /// Recipients with the app open store detail; others hit store via web page.
  static Future<void> shareStore({
    required int storeId,
    required String storeName,
  }) async {
    final link = DeepLinkService.storeShareUrl(storeId);
    final caption = await _tr('txt_share_store_on_inbozor');

    final buffer = StringBuffer();
    buffer.writeln(storeName);
    buffer.writeln();
    buffer.writeln(caption);
    buffer.write(link);

    await SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: storeName,
      ),
    );
  }

  static Future<String> _tr(String key) async {
    try {
      final box = await Hive.openBox('settings');
      var lang = (box.get('locale') ?? 'ru').toString().toLowerCase();
      if (lang == 'tj') lang = 'tg';
      return translations[lang]?[key] ??
          translations['ru']?[key] ??
          key;
    } catch (_) {
      return translations['ru']?[key] ?? key;
    }
  }
}
