# Product Share Deep Links — Server Setup

Shared product links look like:

`https://mudir.inbozor.app/product/{PRODUCT_ID}`

## What the app already does

- Share button on product detail
- Opens product detail when app is installed (`app_links`)
- Custom scheme: `inbozor://product/{id}`
- Android App Links + iOS Universal Links configured in the app

## What you must host on `mudir.inbozor.app`

### 1) Product landing page (required for store fallback)

Serve this HTML for every URL matching `/product/{id}`:

- Copy contents of `product/index.html`
- Route example (Laravel):

```php
Route::get('/product/{id}', function ($id) {
    return response()->file(public_path('share/product.html'));
})->where('id', '[0-9]+');
```

Or nginx rewrite all `/product/*` to this HTML file.

Behavior of the page:

1. Tries `inbozor://product/{id}`
2. If app not installed → App Store / Play Store

Stores used:

- App Store: https://apps.apple.com/in/app/inbozor/id6771488951
- Play Store: https://play.google.com/store/apps/details?id=com.inbozor.user

### 2) Android Digital Asset Links

Host at:

`https://mudir.inbozor.app/.well-known/assetlinks.json`

Replace `REPLACE_WITH_YOUR_RELEASE_SHA256_FINGERPRINT` with your Play signing cert SHA-256.

Get it:

```bash
keytool -list -v -keystore your-release.keystore -alias your-alias
```

Or from Play Console → App integrity → App signing key certificate → SHA-256.

Content-Type must be `application/json`.

### 3) Apple App Site Association

Host at:

`https://mudir.inbozor.app/.well-known/apple-app-site-association`

- No `.json` extension
- Content-Type: `application/json`
- HTTPS only
- Team ID already set to `L7Q4D4F69G`

In Xcode: Signing & Capabilities → Associated Domains → `applinks:mudir.inbozor.app` (already in `Runner.entitlements`).

## Quick test

1. Open a product → tap Share → copy link
2. Phone with app installed → open link → product detail
3. Phone without app → open link → store page
4. Custom scheme test: `adb shell am start -a android.intent.action.VIEW -d "inbozor://product/1"`
