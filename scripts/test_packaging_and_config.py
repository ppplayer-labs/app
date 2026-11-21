"""Regression guards for PPPlayer packaging, media controls, and legacy WebView cleanup."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class PackagingAndConfigTests(unittest.TestCase):
    def test_macos_window_removes_legacy_webkit_scan_and_preserves_media_control_opt_out(self):
        swift = (ROOT / 'macos/Runner/MainFlutterWindow.swift').read_text(encoding='utf-8')
        self.assertIn('setenv("CEF_SYSTEM_MEDIA_CONTROLS", "0", 1)', swift)
        self.assertNotIn('import WebKit', swift)
        self.assertNotIn('patchTimer', swift)
        self.assertNotIn('schedulePatchScan', swift)
        self.assertNotIn('override func miniaturize', swift)

    def test_legacy_windows_webview_dependencies_removed(self):
        app_pubspec = (ROOT / 'pubspec.yaml').read_text(encoding='utf-8')
        patch_pubspec = (
            ROOT / 'lib/core/playback/packages/youtube_player_iframe_macos_patch/package/pubspec.yaml'
        ).read_text(encoding='utf-8')
        win_cmake = (ROOT / 'windows/CMakeLists.txt').read_text(encoding='utf-8')
        workflow = (ROOT / '.github/workflows/release.yml').read_text(encoding='utf-8')

        self.assertNotIn('webview_win_floating', app_pubspec)
        self.assertNotIn('webview_win_floating', patch_pubspec)
        self.assertNotIn('webview_win_floating', win_cmake)
        self.assertNotIn('Microsoft.Web.WebView2', workflow)
        self.assertNotIn('libwebkit2gtk', workflow)

    def test_android_min_sdk_aligned_to_24(self):
        gradle = (ROOT / 'android/app/build.gradle.kts').read_text(encoding='utf-8')
        app_pubspec = (ROOT / 'pubspec.yaml').read_text(encoding='utf-8')
        self.assertIn('24', gradle)
        self.assertIn('min_sdk_android: 24', app_pubspec)

    def test_linux_packaging_sandbox_and_media_controls_configured(self):
        snap = (ROOT / 'snap/snapcraft.yaml').read_text(encoding='utf-8')
        flatpak = (ROOT / 'packaging/linux/flatpak/com.ppplayer.PPPlayer.yml').read_text(encoding='utf-8')
        build_sh = (ROOT / 'packaging/linux/scripts/build_linux.sh').read_text(encoding='utf-8')

        # Containerized formats explicitly opt into inner-sandbox opt-out.
        self.assertIn('FLUTTER_CHROMIUM_WEBVIEW_ALLOW_CONTAINER_NO_SANDBOX: "1"', snap)
        self.assertIn('CEF_SYSTEM_MEDIA_CONTROLS: "0"', snap)
        self.assertIn('--env=FLUTTER_CHROMIUM_WEBVIEW_ALLOW_CONTAINER_NO_SANDBOX=1', flatpak)
        self.assertIn('--env=CEF_SYSTEM_MEDIA_CONTROLS=0', flatpak)

        # Standard .deb ships scoped AppArmor userns profile and drops webkit2gtk.
        self.assertIn('/etc/apparmor.d/ppplayer', build_sh)
        self.assertIn('userns,', build_sh)
        self.assertNotIn('libwebkit2gtk', build_sh)
        self.assertNotIn('ALLOW_CONTAINER_NO_SANDBOX', build_sh)

    def test_desktop_runners_default_cef_system_media_controls_off(self):
        win_main = (ROOT / 'windows/runner/main.cpp').read_text(encoding='utf-8')
        linux_app = (ROOT / 'linux/runner/my_application.cc').read_text(encoding='utf-8')
        self.assertIn('CEF_SYSTEM_MEDIA_CONTROLS', win_main)
        self.assertIn('CEF_SYSTEM_MEDIA_CONTROLS', linux_app)


if __name__ == '__main__':
    unittest.main()
