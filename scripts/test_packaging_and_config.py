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

    def test_release_workflow_gates_all_publication_behind_explicit_approval(self):
        workflow = (ROOT / '.github/workflows/release.yml').read_text(encoding='utf-8')

        # Split top-level jobs under `jobs:` without requiring third-party YAML libs.
        jobs_section = workflow.split('\njobs:\n', 1)[1]
        jobs = {}
        current_job = None
        current_lines = []
        for line in jobs_section.splitlines():
            if line.startswith('  ') and not line.startswith('   ') and line.rstrip().endswith(':'):
                if current_job is not None:
                    jobs[current_job] = '\n'.join(current_lines)
                current_job = line.strip()[:-1]
                current_lines = [line]
            elif current_job is not None:
                current_lines.append(line)
        if current_job is not None:
            jobs[current_job] = '\n'.join(current_lines)

        self.assertIn('build-linux', jobs)
        self.assertIn('publish-release', jobs)

        # Ordinary build jobs (which run on push to main) must still build & upload
        # artifacts, including the Snap package, but MUST NEVER publish or receive
        # store publishing credentials.
        for job_name, job_body in jobs.items():
            if job_name == 'publish-release':
                continue
            self.assertNotIn(
                'snapcore/action-publish',
                job_body,
                f'{job_name} must not publish to Snap Store outside publish-release',
            )
            self.assertNotIn(
                'softprops/action-gh-release',
                job_body,
                f'{job_name} must not create GitHub Releases outside publish-release',
            )
            self.assertNotIn(
                'SNAPCRAFT_STORE_CREDENTIALS',
                job_body,
                f'{job_name} must not receive Snap Store publishing credentials',
            )

        self.assertIn('snapcore/action-build@v1', jobs['build-linux'])
        self.assertIn('PPPlayer-Linux-Snap', jobs['build-linux'])

        # publish-release must require all platform builds AND explicit workflow_dispatch approval.
        publish_job = jobs['publish-release']
        self.assertIn(
            'needs: [validate-and-test, build-android, build-macos, build-windows, build-linux]',
            publish_job,
        )
        self.assertIn(
            "if: github.event_name == 'workflow_dispatch' && inputs.approve_publication == true && needs.validate-and-test.outputs.is_new_version == 'true'",
            publish_job,
        )
        self.assertIn('snapcore/action-publish@v1', publish_job)
        self.assertIn(
            "if: github.event_name == 'workflow_dispatch' && inputs.approve_publication == true && env.SNAPCRAFT_STORE_CREDENTIALS != ''",
            publish_job,
        )
        self.assertIn('softprops/action-gh-release@v2', publish_job)

    def test_pr_validation_workflow_cannot_publish_or_access_release_secrets(self):
        pr_workflow = (ROOT / '.github/workflows/pr-validation.yml').read_text(encoding='utf-8')
        self.assertIn('pull_request:', pr_workflow)
        self.assertIn('- main', pr_workflow)
        self.assertIn('contents: read', pr_workflow)
        self.assertNotIn('contents: write', pr_workflow)
        self.assertNotIn('snapcore/action-publish', pr_workflow)
        self.assertNotIn('softprops/action-gh-release', pr_workflow)
        self.assertNotIn('secrets.', pr_workflow)
        self.assertNotIn('SNAPCRAFT_STORE_CREDENTIALS', pr_workflow)
        self.assertNotIn('ANDROID_KEYSTORE', pr_workflow)
        self.assertNotIn('MACOS_CERTIFICATE', pr_workflow)
        self.assertNotIn('APPLE_ID', pr_workflow)
        for required_job in [
            'validate-and-test:',
            'build-android:',
            'build-macos:',
            'build-windows:',
            'build-linux:',
        ]:
            self.assertIn(required_job, pr_workflow)


if __name__ == '__main__':
    unittest.main()
