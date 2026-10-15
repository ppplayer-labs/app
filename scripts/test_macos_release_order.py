"""Regression guard for final macOS release preparation order (no uploads)."""
from pathlib import Path
import unittest

class ReleaseOrderTests(unittest.TestCase):
    def test_final_containers_follow_app_signing_and_stapling(self):
        workflow = (Path(__file__).resolve().parents[1] / '.github/workflows/release.yml').read_text()
        self.assertLess(workflow.index('xcrun stapler staple PPPlayer.app'),
                        workflow.index('create-dmg PPPlayer.app'))
        self.assertLess(workflow.index('xcrun stapler staple PPPlayer.app'),
                        workflow.index('- name: Package App (ZIP)'))
        self.assertLess(workflow.index('xcrun stapler staple PPPlayer-macOS.dmg'),
                        workflow.index('- name: Upload macOS D'))
        self.assertNotIn('codesign --force --deep', workflow)
        self.assertIn('codesign --verify --deep --strict', workflow)

if __name__ == '__main__':
    unittest.main()
