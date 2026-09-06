# Meta App Events — setup & Test Events

## Credentials (keep in sync)

| Location | Keys |
|----------|------|
| `lib/services/meta_config.dart` | `appId`, `clientToken`, `currency` |
| `android/app/src/main/res/values/strings.xml` | `facebook_app_id`, `facebook_client_token` |
| `ios/Runner/Info.plist` | `FacebookAppID`, `FacebookClientToken` |

Current App ID: `1613586687027233`

## Meta Developer Dashboard (manual)

1. [developers.facebook.com](https://developers.facebook.com) → your app
2. Add platforms:
   - Android: package `com.inbozor.user` + release key hashes
   - iOS: bundle `com.inbozor.user`
3. Turn on **App Events** / connect to **Ads Manager**
4. Events Manager → **Test Events** → copy test device code (optional) or filter by your device

## Verify events in the app

Debug builds already enable Meta SDK debug logs (`[MetaAnalytics] ...` in console).

Force flush after an action if needed (temporary):

```dart
await MetaAnalyticsService.instance.flush();
```

Or run with:

```bash
flutter run --dart-define=META_DEBUG_LOGGING=true
```

### Suggested test path

1. Cold start → App activation
2. OTP login → `Login` + `fb_mobile_complete_registration` (once)
3. Open product → `fb_mobile_content_view`
4. Add to cart → `fb_mobile_add_to_cart`
5. Proceed to checkout → `fb_mobile_initiated_checkout`
6. Place order → Purchase

## Privacy notes

- No ATT prompt is shown (not requested).
- iOS IDFA is only available if the user later grants ATT; SKAdNetwork IDs are configured for install attribution.
- No passwords, OTP, tokens, email, or phone numbers are sent to Meta.
- Purchase currency defaults to `TJS` in `MetaConfig.currency` — change if your market uses another ISO code.

## Ads Manager

After events appear in Events Manager, marketing can create App Install / App Event optimization campaigns. App-side SDK integration alone does not “connect” Ads Manager until the Meta app + store listings are linked in the dashboard.
