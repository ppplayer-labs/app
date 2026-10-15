"""Guard the macOS candidate's architecture/deployment and pod configuration."""
from pathlib import Path
import plistlib
import unittest

ROOT = Path(__file__).resolve().parents[1]

class CandidateConfigTests(unittest.TestCase):
    def test_file_import_entitlement_in_each_build_mode(self):
        for name in ['Release.entitlements', 'DebugProfile.entitlements']:
            with self.subTest(name=name):
                entitlements = plistlib.loads((ROOT / 'macos/Runner' / name).read_bytes())
                self.assertTrue(entitlements.get('com.apple.security.files.user-selected.read-only'))
                self.assertFalse(entitlements.get('com.apple.security.app-sandbox', False))

    def test_arm64_candidate_and_consistent_target(self):
        info = (ROOT / 'macos/Runner/Configs/AppInfo.xcconfig').read_text()
        project = (ROOT / 'macos/Runner.xcodeproj/project.pbxproj').read_text()
        self.assertIn('ARCHS = arm64', info)
        self.assertIn('MACOSX_DEPLOYMENT_TARGET = 13.0', info)
        self.assertNotIn('$(RECOMMENDED_MACOSX_DEPLOYMENT_TARGET)', project)
        self.assertNotIn('Pods-Runner.profile.xcconfig', info)
        self.assertIn('Pods-Runner.release.xcconfig', (ROOT / 'macos/Flutter/Flutter-Release.xcconfig').read_text())

if __name__ == '__main__':
    unittest.main()
