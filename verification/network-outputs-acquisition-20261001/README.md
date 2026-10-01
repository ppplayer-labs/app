# Network Outputs bookmark acquisition verification

Implemented at the acquisition boundary. Cast architecture and NetworkOutputController matching are unchanged.

## Files changed for this fix

- `lib/core/local_library/local_file_resolver.dart`: public bookmark resolver delegates to the existing local-files channel; revoked/unavailable resolution returns null; release delegates to the same channel.
- `lib/core/network_outputs/network_output_providers.dart`: inject Apple acquisition on iOS/macOS; accept file URIs/absolute paths, validate base64 bookmark input, resolve through local_library, canonicalize with failure cleanup, retain native access in the file lease.
- `lib/core/network_outputs/network_media_factory.dart`: infer local MIME from the authorized canonical file when the opaque bookmark has no extension; release unknown formats.
- `lib/core/network_outputs/capability_resolver.dart`: share URI-to-MIME inference for resolved files.
- `lib/core/network_outputs/local_media_server.dart`: memoize lease release; revoke URL before draining accepted reads and release native scope after their streams close. Expiry prevents new requests without truncating an accepted file read.
- `lib/core/network_outputs/cast/fake_cast_platform_client.dart`: asynchronous connecting/connected callbacks, generation guards for superseded operations, endpoint/session/item propagation, stale command validation and timer cleanup.
- `ios/Runner/AppDelegate.swift`: register the missing local_files native channel; implement bookmark creation/resolution/release with one retained access reference per successful resolution.
- `macos/Runner/AppDelegate.swift`: matching local-library channel with macOS security-scoped bookmark options.
- `lib/shared/widgets/pp_image.dart`: only HTTP(S) artwork enters the cache; opaque locators use fallback; decode file URIs correctly; use an existing fallback asset; preserve texture repeat/tint.
- `lib/features/player/player_screen.dart`: route the texture image through PPImage.
- `lib/features/library/library_screen.dart`: route three direct NetworkImage providers through PPImage.
- `test/core/network_outputs/ios_file_lease_test.dart`: replace mirrored acquisition code with seven production-boundary regressions.
- `test/shared/widgets/pp_image_test.dart`: regressions for encoded local artwork paths and opaque artwork avoiding the network cache.
- `integration_test/network_output_ios_bookmark_test.dart`: native iOS bookmark -> real media factory/controller/backend -> Fake Cast -> real HTTP receiver.

The workspace contained unrelated existing changes; this list describes the files touched by this fix.

## Tests and results

- `flutter analyze`: no issues found.
- `flutter test`: 274 tests passed.
- Bookmark regressions: valid bookmark -> file lease -> HTTP URL/read; file URI unchanged; invalid bookmark; revoked bookmark; canonicalization failure cleanup; 32 MiB in-flight read survives expiry with scope retained; Fake Cast handoff and identity matching with stale commands rejected.
- Image regressions: percent-encoded spaces/Unicode in file URI; opaque locator never reaches CachedNetworkImage.
- `flutter build ios --simulator --debug --no-pub`: passed, including the new Swift handler.
- `flutter test integration_test/network_output_ios_bookmark_test.dart -d E8E59C25-C140-4531-9455-57147A3F753C`: passed on iPhone 17 Pro / iOS 26.5 simulator. Bookmark creation and resolution use the real native MethodChannel, not a mock. Local playback and Cast receiver behavior are simulated; HTTP file serving and reading are real.

## Native handoff evidence

From `ios-bookmark-handoff.log`:

```text
[Output] file_lease.bookmark_resolved access=active
[Output] local_server.start interface=127.0.0.1 port=57192
[Output] handoff.local_to_remote position=0
[Output] google_cast load.start mime=audio/mpeg ... item=item_1
[Output] connect.ready kind=googleCast
[Output] local_server.request method=GET range=false
[Verification] native iOS bookmark resolved -> lease created -> HTTP 200 -> Fake Cast playing
[Output] local_server.stop
[Output] file_lease.released access=stopped
[Verification] receiver disconnected -> lease released
00:02 +1: All tests passed!
```

No bookmark data, media bearer tokens, or filesystem paths are printed by acquisition diagnostics.
