# Fix: shared product link opens browser error instead of app

## Why this happens

`https://mudir.inbozor.app/product/80` is handled by your **Laravel server**, not by Flutter.

Right now Laravel has **no route** for `/product/{id}`, so it tries to show a 404 page and crashes with:

`View [404] not found.`

Until this page exists on the server, the phone will always open the browser error — the app cannot intercept a broken HTTPS page.

## Fix (do this on Laravel backend `mudir.inbozor.app`)

### Step 1 — Add Blade view

Copy:

`deep_link_hosting/laravel/resources/views/product_share.blade.php`

To your Laravel project:

`resources/views/product_share.blade.php`

### Step 2 — Add route in `routes/web.php`

Paste the route from:

`deep_link_hosting/laravel/routes_web_snippet.php`

**Put it above any catch-all / fallback 404 route.**

Minimal version:

```php
Route::get('/product/{id}', function ($id) {
    return view('product_share', ['id' => $id]);
})->where('id', '[0-9]+');
```

### Step 3 — Deploy & clear cache

```bash
php artisan route:clear
php artisan view:clear
php artisan config:clear
```

### Step 4 — Test in browser

Open: https://mudir.inbozor.app/product/80

You should see **“Open in inBozor”** (not Laravel error).

Then:

- App installed → opens product detail (via `inbozor://product/80`)
- App not installed → App Store / Play Store

## Optional (open app directly, skip browser)

Copy `.well-known` files to Laravel `public/.well-known/`:

- `assetlinks.json` (replace Play SHA-256)
- `apple-app-site-association`

See `deep_link_hosting/README.md`.

## Flutter side

Already done — share button + deep link listener for:

- `https://mudir.inbozor.app/product/{id}`
- `inbozor://product/{id}`

No Flutter change is required for this Laravel 404. The server route is the missing piece.
