import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../service/translations.dart';
import 'deep_link_service.dart';

class ProductShareService {
  ProductShareService._();

  /// Opens the native share sheet with a product link.
  /// Recipients with the app open product detail; others hit store via web page.
  static Future<void> shareProduct({
    required int productId,
    required String productName,
    String? priceText,
  }) async {
    final link = DeepLinkService.productShareUrl(productId);
    final caption = await _tr('txt_share_product_on_inbozor');

    final buffer = StringBuffer();
    buffer.writeln(productName);
    if (priceText != null && priceText.trim().isNotEmpty) {
      buffer.writeln(priceText);
    }
    buffer.writeln();
    buffer.writeln(caption);
    buffer.write(link);

    await SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: productName,
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
