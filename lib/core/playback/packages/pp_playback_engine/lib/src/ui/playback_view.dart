import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart' as mk;
import 'pp_logo_loader.dart';

import '../engine/playback_controller.dart';
import '../models/playback_status.dart';

class PlaybackView extends StatefulWidget {
  final PlaybackController controller;
  final PlaybackStatus status;
  final BoxFit fit;
  final bool showControls;
  final mk.SubtitleViewConfiguration? subtitleViewConfiguration;

  const PlaybackView({
    super.key,
    required this.controller,
    required this.status,
    this.fit = BoxFit.cover,
    this.showControls = false,
    this.subtitleViewConfiguration,
  });

  @override
  State<PlaybackView> createState() => _PlaybackViewState();
}

class _PlaybackViewState extends State<PlaybackView> {
  Size? _lastSize;
  Timer? _pumpTimer;

  @override
  void dispose() {
    _pumpTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renderer = widget.controller.renderer;
    final isWindows = !kIsWeb && Platform.isWindows;
    // Only legacy floating Win32 webviews (non-Widget, non-MediaKit) needed
    // extra post-resize layout pumps. Skipping this for texture-backed
    // ChromiumWebView and MediaKit avoids 10 redundant rebuilds per resize tick.
    if (isWindows && renderer != null && renderer is! Widget && renderer is! mk.VideoController) {
      final currentSize = MediaQuery.sizeOf(context);
      if (_lastSize != null && _lastSize != currentSize) {
        _pumpTimer?.cancel();
        int pumpCount = 0;
        _pumpTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() {});
          pumpCount++;
          if (pumpCount >= 10) {
            timer.cancel();
          }
        });
      }
      _lastSize = currentSize;
    }

    if (renderer is Widget) {
      return Stack(
        fit: StackFit.expand,
        children: [
          renderer,
          if (widget.status.state == PlaybackState.preparing ||
              widget.status.state == PlaybackState.buffering)
            Center(child: PPLogoLoader(size: 60, color: Colors.white)),
        ],
      );
    }
    if (renderer == null) {
      // Headless mode (e.g. NativeServicePlaybackEngine on Android)
      return const ColoredBox(color: Colors.black);
    }

    return mk.Video(
      key: ObjectKey(renderer),
      controller: renderer,
      // Mobile background audio and explicit pause belong to the playback
      // controller, including when this surface renders an audio-only file.
      pauseUponEnteringBackgroundMode:
          defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.android,
      resumeUponEnteringForegroundMode: false,
      controls:
          widget.showControls ? mk.MaterialVideoControls : mk.NoVideoControls,
      fit: widget.fit,
      fill: Colors.transparent,
      subtitleViewConfiguration:
          widget.subtitleViewConfiguration ??
          const mk.SubtitleViewConfiguration(),
    );
  }
}
