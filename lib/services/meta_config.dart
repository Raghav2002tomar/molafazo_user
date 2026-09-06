/// Central Meta / Facebook App Events credentials for inBozor.
///
/// Platform native config reads the same values from:
/// - Android: `android/app/src/main/res/values/strings.xml`
/// - iOS: `ios/Runner/Info.plist`
///
/// Keep those three locations in sync when rotating App ID / Client Token.
class MetaConfig {
  MetaConfig._();

  static const String appId = '1613586687027233';
  static const String clientToken = 'ad9344f62a68f2148b66372ea4921ede';
  static const String displayName = 'inBozor';

  /// Market currency for purchase / cart value events (UI shows "c.").
  static const String currency = 'TJS';

  /// Enable verbose Meta SDK + service logs in debug builds only.
  static const bool debugLogging = bool.fromEnvironment(
    'META_DEBUG_LOGGING',
    defaultValue: false,
  );
}
