#!/usr/bin/env bash
export LIBGL_ALWAYS_SOFTWARE=1
export WEBKIT_DISABLE_COMPOSITING_MODE=1
export GDK_BACKEND=x11
export FLUTTER_WEBVIEW_NO_SANDBOX=1
export GALLIUM_DRIVER=llvmpipe
echo "Starting Flutter on Linux with software rendering and X11 backend..."
/snap/bin/flutter run -d linux --dart-define=PPPLAYER_API_BASE_URL=https://ppplayer.com --no-enable-impeller
