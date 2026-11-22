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

    def test_temporary_ads_free_release_has_no_admob_sdk_or_ids(self):
        pubspec = (ROOT / 'pubspec.yaml').read_text(encoding='utf-8')
        pubspec_lock = (ROOT / 'pubspec.lock').read_text(encoding='utf-8')
        manifest = (ROOT / 'android/app/src/main/AndroidManifest.xml').read_text(encoding='utf-8')
        info_plist = (ROOT / 'ios/Runner/Info.plist').read_text(encoding='utf-8')
        ad_service = (ROOT / 'lib/core/services/ad_service.dart').read_text(encoding='utf-8')
        banner_widget = (ROOT / 'lib/shared/widgets/banner_ad_widget.dart').read_text(encoding='utf-8')
        main_dart = (ROOT / 'lib/main.dart').read_text(encoding='utf-8')

        self.assertNotIn('google_mobile_ads', pubspec)
        self.assertNotIn('google_mobile_ads', pubspec_lock)
        self.assertNotIn('com.google.android.gms.ads.APPLICATION_ID', manifest)
        self.assertNotIn('ca-app-pub-', manifest)
        self.assertNotIn('GADApplicationIdentifier', info_plist)
        self.assertNotIn('SKAdNetworkItems', info_plist)
        self.assertNotIn('google_mobile_ads', ad_service)
        self.assertNotIn('ca-app-pub-', ad_service)
        self.assertNotIn('ConsentInformation', ad_service)
        self.assertNotIn('google_mobile_ads', banner_widget)
        self.assertNotIn('MobileAds.instance.initialize', main_dart)

    def test_android_webview_quotes_video_id_for_js_safety(self):
        service_kt = (
            ROOT / 'android/app/src/main/kotlin/com/ppplayer/app/CustomWebViewService.kt'
        ).read_text(encoding='utf-8')
        self.assertIn('JSONObject.quote(videoId)', service_kt)
        self.assertNotIn("loadVideo('$videoId'", service_kt)
        self.assertNotIn("cueVideo('$videoId'", service_kt)

    def test_android_v35_styles_use_modern_edge_to_edge_cutout_mode(self):
        for rel in (
            'android/app/src/main/res/values-v35/styles.xml',
            'android/app/src/main/res/values-night-v35/styles.xml',
        ):
            xml = (ROOT / rel).read_text(encoding='utf-8')
            self.assertIn('>always<', xml)
            self.assertNotIn('>shortEdges<', xml)
            self.assertNotIn('windowDrawsSystemBarBackgrounds', xml)

    def test_android_release_enables_r8_optimization_and_symbols(self):
        gradle = (ROOT / 'android/app/build.gradle.kts').read_text(encoding='utf-8')
        props = (ROOT / 'android/gradle.properties').read_text(encoding='utf-8')
        proguard = (ROOT / 'android/app/proguard-rules.pro').read_text(encoding='utf-8')
        self.assertIn('isMinifyEnabled = true', gradle)
        self.assertIn('isShrinkResources = true', gradle)
        self.assertIn('proguard-android-optimize.txt', gradle)
        self.assertIn('debugSymbolLevel = "SYMBOL_TABLE"', gradle)
        self.assertNotIn('android.r8.optimizedResourceShrinking=false', props)
        self.assertIn('PPPlayerCastOptionsProvider', proguard)
        self.assertIn('JavascriptInterface', proguard)

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

    def _split_workflow_jobs(self, workflow_text: str) -> dict[str, str]:
        jobs_section = workflow_text.split('\njobs:\n', 1)[1]
        jobs: dict[str, str] = {}
        current_job = None
        current_lines: list[str] = []
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
        return jobs

    def test_linux_packaging_has_no_masked_flatpak_errors_or_global_sha_sed(self):
        build_sh = (ROOT / 'packaging/linux/scripts/build_linux.sh').read_text(encoding='utf-8')
        self.assertNotIn('flatpak-builder ', build_sh.split('|| true')[0] if '|| true' in build_sh else '')
        for line in build_sh.splitlines():
            if 'flatpak-builder' in line or 'flatpak build-bundle' in line:
                self.assertNotIn('|| true', line, f'Masked Flatpak error found: {line}')
        self.assertNotIn('s|sha256: [0-9a-fA-F]*|', build_sh)
        self.assertIn('update_flatpak_manifest.py', build_sh)

    def test_release_workflow_separates_github_and_snap_publication_with_strict_guards(self):
        workflow = (ROOT / '.github/workflows/release.yml').read_text(encoding='utf-8')
        jobs = self._split_workflow_jobs(workflow)

        self.assertIn('build-linux', jobs)
        self.assertIn('build-windows', jobs)
        self.assertIn('publish-github-release', jobs)
        self.assertIn('publish-snap', jobs)
        self.assertNotIn('publish-release', jobs)

        # Workflow inputs must expose independent, default-false publication controls + version/SHA guards.
        on_section = workflow.split('\njobs:\n', 1)[0]
        self.assertNotIn('approve_publication:', on_section)
        self.assertIn('publish_github_release:', on_section)
        self.assertIn('publish_snap_store:', on_section)
        self.assertIn('expected_version:', on_section)
        self.assertIn('expected_sha:', on_section)
        self.assertEqual(on_section.count('default: false'), 2)

        # Build jobs must NEVER publish or receive Snap Store credentials.
        for job_name, job_body in jobs.items():
            if job_name not in ('publish-github-release', 'publish-snap'):
                self.assertNotIn('snapcore/action-publish', job_body)
                self.assertNotIn('softprops/action-gh-release', job_body)
                self.assertNotIn('SNAPCRAFT_STORE_CREDENTIALS', job_body)

        self.assertIn('snapcore/action-build@v1', jobs['build-linux'])
        self.assertIn('PPPlayer-Linux-Snap', jobs['build-linux'])

        # GitHub Release job: independent of Snap, requires all platform builds, guards version/SHA/tag.
        gh_job = jobs['publish-github-release']
        self.assertIn(
            'needs: [validate-and-test, build-android, build-macos, build-windows, build-linux]',
            gh_job,
        )
        self.assertIn(
            "if: github.event_name == 'workflow_dispatch' && inputs.publish_github_release == true && needs.validate-and-test.outputs.should_build == 'true'",
            gh_job,
        )
        self.assertIn('contents: write', gh_job)
        self.assertIn('softprops/action-gh-release@v2', gh_job)
        self.assertNotIn('snapcore/action-publish', gh_job)
        self.assertNotIn('SNAPCRAFT_STORE_CREDENTIALS', gh_job)
        self.assertIn('EXPECTED_VERSION', gh_job)
        self.assertIn('EXPECTED_SHA', gh_job)
        self.assertIn('git ls-remote --tags origin', gh_job)

        # Snap Store job: independent of GitHub Release, requires validate + build-linux, read-only repo perms.
        snap_job = jobs['publish-snap']
        self.assertIn('needs: [validate-and-test, build-linux]', snap_job)
        self.assertIn(
            "if: github.event_name == 'workflow_dispatch' && inputs.publish_snap_store == true && needs.validate-and-test.outputs.should_build == 'true'",
            snap_job,
        )
        self.assertIn('contents: read', snap_job)
        self.assertNotIn('contents: write', snap_job)
        self.assertIn('snapcore/action-publish@v1', snap_job)
        self.assertNotIn('softprops/action-gh-release', snap_job)
        self.assertIn('if [ -z "$SNAPCRAFT_STORE_CREDENTIALS" ]; then', snap_job)
        self.assertNotIn('echo "$SNAPCRAFT_STORE_CREDENTIALS"', snap_job)
        self.assertIn('EXPECTED_VERSION', snap_job)
        self.assertIn('EXPECTED_SHA', snap_job)

        # Evaluate the workflow decision matrix across all publication combinations.
        def eval_channels(
            *,
            event: str,
            publish_github: bool = False,
            publish_snap: bool = False,
            builds_ok: bool = True,
            linux_ok: bool = True,
            should_build: bool = True,
        ) -> tuple[bool, bool]:
            gh_runs = (
                event == 'workflow_dispatch'
                and publish_github
                and should_build
                and builds_ok
                and linux_ok
            )
            snap_runs = (
                event == 'workflow_dispatch'
                and publish_snap
                and should_build
                and linux_ok
            )
            return gh_runs, snap_runs

        self.assertEqual(eval_channels(event='push'), (False, False))
        self.assertEqual(eval_channels(event='pull_request'), (False, False))
        self.assertEqual(eval_channels(event='workflow_dispatch'), (False, False))
        self.assertEqual(
            eval_channels(event='workflow_dispatch', publish_github=True, publish_snap=False),
            (True, False),
        )
        self.assertEqual(
            eval_channels(event='workflow_dispatch', publish_github=False, publish_snap=True),
            (False, True),
        )
        self.assertEqual(
            eval_channels(event='workflow_dispatch', publish_github=True, publish_snap=True),
            (True, True),
        )
        self.assertEqual(
            eval_channels(
                event='workflow_dispatch',
                publish_github=True,
                publish_snap=True,
                builds_ok=False,
                linux_ok=True,
            ),
            (False, True),
        )
        self.assertEqual(
            eval_channels(
                event='workflow_dispatch',
                publish_github=True,
                publish_snap=True,
                builds_ok=False,
                linux_ok=False,
            ),
            (False, False),
        )

    def test_release_workflow_excludes_unsigned_windows_msix_from_public_github_release(self):
        workflow = (ROOT / '.github/workflows/release.yml').read_text(encoding='utf-8')
        jobs = self._split_workflow_jobs(workflow)

        # Microsoft Partner Center packaging job remains intact and uploads CI artifact.
        win_job = jobs['build-windows']
        self.assertIn('dart run msix:create', win_job)
        self.assertIn('name: PPPlayer-Windows-MSIX', win_job)

        # Public GitHub Release job must NEVER copy or ship *.msix files.
        gh_job = jobs['publish-github-release']
        self.assertNotIn('PPPlayer-Windows.msix', gh_job)
        self.assertNotIn('cp artifacts/PPPlayer-Windows-MSIX', gh_job)
        self.assertIn('find release-assets -iname "*.msix"', gh_job)

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
        release_workflow = (ROOT / '.github/workflows/release.yml').read_text(encoding='utf-8')
        self.assertNotIn('runs-on: macos-14', pr_workflow)
        self.assertNotIn('runs-on: macos-14', release_workflow)


if __name__ == '__main__':
    unittest.main()
