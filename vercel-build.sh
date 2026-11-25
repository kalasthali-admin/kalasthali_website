#!/usr/bin/env bash

set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.1}"
FLUTTER_ROOT="$PWD/.vercel/flutter"

git config --global --add safe.directory "$PWD"

if command -v flutter >/dev/null 2>&1; then
  FLUTTER_ROOT="$(dirname "$(dirname "$(command -v flutter)")")"
else
  git config --global --add safe.directory "$FLUTTER_ROOT"
  if [ ! -x "$FLUTTER_ROOT/bin/flutter" ]; then
    mkdir -p "$PWD/.vercel"
    curl -fL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -o /tmp/flutter.tar.xz
    tar -xf /tmp/flutter.tar.xz -C "$PWD/.vercel"
  fi
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"

flutter config --enable-web
flutter pub get
flutter build web --release --no-wasm-dry-run \
  --dart-define=WHATSAPP_BUSINESS_NUMBER="${WHATSAPP_BUSINESS_NUMBER:-}" \
  --dart-define=INSTAGRAM_URL="${INSTAGRAM_URL:-}" \
  --dart-define=FACEBOOK_URL="${FACEBOOK_URL:-}" \
  --dart-define=AMAZON_URL="${AMAZON_URL:-}" \
  --dart-define=MYNTRA_URL="${MYNTRA_URL:-}" \
  --dart-define=ADMIN_TEST_MODE="${ADMIN_TEST_MODE:-false}" \
  --dart-define=VAPID_PUBLIC_KEY="${VAPID_PUBLIC_KEY}"

# Keep Flutter's entrypoint for commerce routes, then generate the public pages.
mv build/web/index.html build/web/flutter.html
node scripts/prerender-products.cjs
node scripts/build-public-config.cjs

dart pub global activate jaspr_cli 0.23.5
(
  cd public_site
  dart pub get
  "$HOME/.pub-cache/bin/jaspr" build
)

cp public_site/build/jaspr/index.html build/web/index.html
cp -R public_site/build/jaspr/about public_site/build/jaspr/contact \
  public_site/build/jaspr/privacy-policy public_site/build/jaspr/terms-of-service \
  public_site/build/jaspr/refund-policy build/web/
cp public_site/build/jaspr/404/index.html build/web/404.html
cp public_site/build/jaspr/public.css public_site/build/jaspr/public.js build/web/
