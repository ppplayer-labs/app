const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

// Exercise the actual injected script, rather than a second implementation.
const source = fs.readFileSync(path.join(__dirname, '../../ios/Runner/AppDelegate.swift'), 'utf8');
const script = source.match(/private let visibilityPatchScript = """([\s\S]*?)"""/)[1];
const handlers = new Map();
const messages = [];
const session = {
  metadata: { title: 'Song' },
  setActionHandler(action, handler) { handlers.set(action, handler); },
};
const document = { addEventListener() {} };
const window = {
  addEventListener() {},
  webkit: { messageHandlers: { ppplayerMediaCommand: {
    postMessage(message) { messages.push(JSON.parse(JSON.stringify(message))); },
  } } },
};
const context = vm.createContext({ window, document, navigator: { mediaSession: session } });
vm.runInContext(script, context);
assert.equal(document.hidden, false);
assert.equal(document.visibilityState, 'visible');
assert.equal(session.metadata.title, 'Song');

// Later YouTube registration and cleanup must not replace our pause intent.
let bypassed = false;
session.setActionHandler('pause', () => { bypassed = true; });
handlers.get('pause')({});
session.setActionHandler('pause', null);
handlers.get('pause')({});
handlers.get('play')({});
handlers.get('seekto')({ seekTime: 12.5 });
handlers.get('seekto')({ seekTime: NaN });
handlers.get('nexttrack')({});
handlers.get('previoustrack')({});
assert.equal(bypassed, false);
assert.deepEqual(messages, [
  { command: 'pause' }, { command: 'pause' }, { command: 'play' },
  { command: 'seek', positionMs: 12500 },
  { command: 'next' }, { command: 'previous' },
]);
const unrelated = () => {};
session.setActionHandler('skipad', unrelated);
assert.equal(handlers.get('skipad'), unrelated);
vm.runInContext(script, context);
handlers.get('pause')({});
assert.equal(messages.length, 7);
console.log('PASS: WebKit system actions reach the native intent bridge; later registrations cannot bypass it.');
