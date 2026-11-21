"""Exercise production terminate: methods against a fake AppKit/CEF handshake."""
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parents[1]


def _resolve_chromium_plugin_mm() -> Path:
    pkg_config = ROOT / '.dart_tool' / 'package_config.json'
    if pkg_config.is_file():
        data = json.loads(pkg_config.read_text(encoding='utf-8'))
        for pkg in data.get('packages', []):
            if pkg.get('name') == 'flutter_chromium_webview':
                root_uri = pkg.get('rootUri', '')
                if root_uri.startswith('file://'):
                    base = Path(unquote(urlparse(root_uri).path))
                else:
                    base = (pkg_config.parent / root_uri).resolve()
                candidate = base / 'macos/Classes/FlutterChromiumWebviewPlugin.mm'
                if candidate.is_file():
                    return candidate
    return ROOT / 'third_party/chromium/packages/flutter_chromium_webview/macos/Classes/FlutterChromiumWebviewPlugin.mm'


@unittest.skipUnless(sys.platform == 'darwin' and shutil.which('clang++'), 'macOS Objective-C++ required')
class QuitHandshakeTests(unittest.TestCase):
    def test_flutter_retry_reaches_appkit_without_repeating_cef_shutdown(self):
        source = _resolve_chromium_plugin_mm().read_text()
        methods = source.split('@implementation ChromiumWebViewApplication', 1)[1].split('@end', 1)[0]
        harness = r'''
#import <Cocoa/Cocoa.h>
#include <functional>
#include <cassert>
static int terminations = 0;
struct CefScopedSendingEvent { CefScopedSendingEvent() {} };
namespace chromium_macos {
struct Runtime {
  int requests = 0;
  std::function<void()> completion;
  static Runtime& Shared() { static Runtime value; return value; }
  void RequestShutdown(std::function<void()> done) {
    if (requests++) return;
    completion = done;
  }
};
}
@interface FakeAppKit : NSObject
- (void)terminate:(id)sender;
- (void)sendEvent:(NSEvent*)event;
@end
@implementation FakeAppKit
- (void)terminate:(id)sender { terminations++; }
- (void)sendEvent:(NSEvent*)event {}
@end
@interface TestApplication : FakeAppKit
@property(nonatomic) BOOL handlingSendEvent;
@property(nonatomic) BOOL chromiumShutdownComplete;
- (void)finishTermination:(id)sender;
@end
@implementation TestApplication
''' + methods + r'''
@end
int main() { @autoreleasepool {
  TestApplication* app = [TestApplication new];
  auto& runtime = chromium_macos::Runtime::Shared();
  [app terminate:nil];
  assert(terminations == 0); // wait for CEF cleanup
  runtime.completion();
  assert(terminations == 1); // Flutter may cancel this initial AppKit attempt
  [app terminate:nil];      // Flutter's later approved-exit retry
  assert(terminations == 2);
  [app terminate:nil];
  assert(terminations == 3);
  assert(runtime.requests == 1);
} }
'''
        with tempfile.TemporaryDirectory() as temp:
            src = Path(temp) / 'quit.mm'
            binary = Path(temp) / 'quit'
            src.write_text(harness)
            built = subprocess.run(['clang++', '-std=c++17', '-fobjc-arc', '-framework', 'Cocoa', str(src), '-o', str(binary)], capture_output=True, text=True)
            self.assertEqual(built.returncode, 0, built.stderr)
            result = subprocess.run([str(binary)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == '__main__':
    unittest.main()
