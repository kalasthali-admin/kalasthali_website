#!/usr/bin/env bash

set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.1}"
FLUTTER_ROOT="$PWD/.vercel/flutter"

# Configure git to trust the Flutter directory (required for running as root on Vercel)
git config --global --add safe.directory "$FLUTTER_ROOT"
git config --global --add safe.directory "$PWD"

if [ ! -x "$FLUTTER_ROOT/bin/flutter" ]; then
  mkdir -p "$PWD/.vercel"
  curl -L "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -o /tmp/flutter.tar.xz
  tar -xf /tmp/flutter.tar.xz -C "$PWD/.vercel"
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
  --dart-define=ADMIN_TEST_MODE="${ADMIN_TEST_MODE:-false}"

# Produce crawlable product HTML after Flutter has emitted its bootstrap assets.
node scripts/prerender-products.cjs
