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
flutter build web --release \
  --dart-define=WHATSAPP_BUSINESS_NUMBER="${WHATSAPP_BUSINESS_NUMBER:-}"
