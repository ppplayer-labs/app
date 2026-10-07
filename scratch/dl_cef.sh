#!/usr/bin/env bash
cd /mnt/c/Users/User/Projects/ppplayermusic/app/build/linux/x64/debug/plugins/flutter_chromium_webview/cef_download/ || exit 1
F="cef_binary_149.0.4+g2f1bfd8+chromium-149.0.7827.156_linux64_minimal.tar.bz2"
U="https://cef-builds.spotifycdn.com/cef_binary_149.0.4%2Bg2f1bfd8%2Bchromium-149.0.7827.156_linux64_minimal.tar.bz2"
until wget -c -t 0 --timeout=30 -O "$F" "$U"; do sleep 3; done
sha256sum "$F"
echo DONE
