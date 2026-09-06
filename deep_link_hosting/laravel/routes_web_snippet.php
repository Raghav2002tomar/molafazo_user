<?php

/**
 * ADD THIS to your Laravel backend: routes/web.php
 *
 * IMPORTANT: put it ABOVE any catch-all / fallback 404 route.
 */

use Illuminate\Support\Facades\Route;

Route::get('/product/{id}', function ($id) {
    if (!ctype_digit((string) $id)) {
        abort(404);
    }

    return response()
        ->view('product_share', ['id' => $id])
        ->header('Cache-Control', 'no-store, no-cache, must-revalidate');
})->where('id', '[0-9]+');

Route::get('/store/{id}', function ($id) {
    if (!ctype_digit((string) $id)) {
        abort(404);
    }

    return response()
        ->view('store_share', ['id' => $id])
        ->header('Cache-Control', 'no-store, no-cache, must-revalidate');
})->where('id', '[0-9]+');

/**
 * Optional: Digital Asset Links + Apple AASA
 * Put the JSON files from deep_link_hosting/.well-known/
 * into your Laravel public/.well-known/ folder:
 *
 *   public/.well-known/assetlinks.json
 *   public/.well-known/apple-app-site-association
 *
 * For AASA, some servers need this extra route (no .json extension):
 */
Route::get('/.well-known/apple-app-site-association', function () {
    $path = public_path('.well-known/apple-app-site-association');
    if (!file_exists($path)) {
        abort(404);
    }
    return response()
        ->file($path, ['Content-Type' => 'application/json']);
});
