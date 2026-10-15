"""Keep diagnostic exports free of signed media URLs, without changing samples."""
import unittest
from capture_android_playback import safe_url


class DiagnosticPrivacyTests(unittest.TestCase):
    def test_signed_media_query_and_fragment_are_removed(self):
        self.assertEqual(safe_url('https://r1.googlevideo.com/videoplayback?expire=123&sig=private#fragment'), 'https://r1.googlevideo.com/videoplayback')

    def test_url_credentials_are_removed(self):
        self.assertEqual(safe_url('https://user:secret@example.com/video?token=private'), 'https://example.com/video')

    def test_inline_media_payload_is_not_exported(self):
        self.assertEqual(safe_url('data:video/webm;base64,PRIVATE_MEDIA'), 'data:[omitted]')

    def test_plain_fixture_host_path_preserved(self):
        self.assertEqual(safe_url('http://127.0.0.1:8769/vp9.webm'), 'http://127.0.0.1:8769/vp9.webm')


if __name__ == '__main__':
    unittest.main()
