{{--
  Place this file in your Laravel backend:
  resources/views/store_share.blade.php
--}}
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>inBozor — Open Store</title>
  <meta name="robots" content="noindex" />
  <style>
    :root {
      --bg: #0f172a;
      --card: #1e293b;
      --text: #f8fafc;
      --muted: #94a3b8;
      --accent: #22c55e;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: radial-gradient(circle at top, #1e293b, var(--bg));
      color: var(--text);
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }
    .card {
      width: 100%;
      max-width: 420px;
      background: var(--card);
      border-radius: 20px;
      padding: 28px 22px;
      text-align: center;
      box-shadow: 0 20px 50px rgba(0,0,0,.35);
    }
    .logo {
      width: 72px;
      height: 72px;
      border-radius: 16px;
      background: #fff;
      margin: 0 auto 16px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 800;
      color: #0f172a;
      font-size: 18px;
    }
    h1 { margin: 0 0 8px; font-size: 22px; }
    p { margin: 0 0 20px; color: var(--muted); line-height: 1.5; }
    .btn {
      display: block;
      width: 100%;
      border: 0;
      border-radius: 12px;
      padding: 14px 16px;
      margin-bottom: 10px;
      font-size: 16px;
      font-weight: 600;
      text-decoration: none;
      color: #fff;
    }
    .btn-primary { background: var(--accent); color: #052e16; }
    .btn-secondary { background: #334155; }
    .hint { font-size: 13px; color: var(--muted); margin-top: 8px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">inBozor</div>
    <h1>Open Store in inBozor</h1>
    <p id="status">Opening the store in the app…</p>
    <a id="openApp" class="btn btn-primary" href="#">Open App</a>
    <a id="storeBtn" class="btn btn-secondary" href="#">Get the App</a>
    <p class="hint">If the app does not open automatically, tap Open App.</p>
  </div>

  <script>
    window.__STORE_ID__ = @json((string) $id);

    (function () {
      var APP_STORE = "https://apps.apple.com/in/app/inbozor/id6771488951";
      var PLAY_STORE = "https://play.google.com/store/apps/details?id=com.inbozor.user";
      var PACKAGE = "com.inbozor.user";
      var storeId = String(window.__STORE_ID__ || "");

      var ua = navigator.userAgent || "";
      var isIOS = /iPhone|iPad|iPod/i.test(ua);
      var isAndroid = /Android/i.test(ua);
      var storeUrl = isIOS ? APP_STORE : PLAY_STORE;

      var openApp = document.getElementById("openApp");
      var storeBtn = document.getElementById("storeBtn");
      var statusEl = document.getElementById("status");

      storeBtn.href = storeUrl;
      storeBtn.textContent = isIOS ? "Download on App Store" : "Get it on Google Play";

      if (!/^\d+$/.test(storeId)) {
        statusEl.textContent = "Install inBozor to browse stores.";
        openApp.style.display = "none";
        return;
      }

      var customUrl = "inbozor://store/" + storeId;
      var intentUrl =
        "intent://store/" + storeId +
        "#Intent;scheme=inbozor;package=" + PACKAGE +
        ";S.browser_fallback_url=" + encodeURIComponent(PLAY_STORE) +
        ";end";

      var launchUrl = isAndroid ? intentUrl : customUrl;
      openApp.href = launchUrl;

      var leftAt = Date.now();
      window.location.href = launchUrl;

      setTimeout(function () {
        if (document.hidden) return;
        if (Date.now() - leftAt < 1400) return;
        statusEl.textContent = "App not installed. Opening the store…";
        window.location.href = storeUrl;
      }, 1800);
    })();
  </script>
</body>
</html>
