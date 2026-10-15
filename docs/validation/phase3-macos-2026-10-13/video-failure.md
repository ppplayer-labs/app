# macOS release candidate: audible playback, blank video

User confirmed audible YouTube playback on the M1 Pro Mac. Both full VIDEO mode
and the mini-player remained blank. CEF host telemetry showed accelerated paints
continuing, and Flutter received IOSurface ports. Playback heartbeat advanced.
These signals alone do not demonstrate visible frames.

Inspection found ResizeBrowser replaced the IOSurface ring without releasing
cached destination Metal textures. Those textures retain the previous generation
and continued receiving blits, while Flutter sampled the newly exported surfaces.
The candidate patch clears that cache before replacing the surfaces. Runtime
verification of the rebuilt Release candidate shows visible content in the full
player, mini-player, and after source switching. The user explicitly confirmed
"Video and sound both work". Actual decoded video resolution was not measured;
the displayed music content used album artwork. This is not 1080p certification.

The original process was terminated with SIGTERM after application-menu Quit
failed to close it during the test. Treat normal quit/cleanup as unverified.
