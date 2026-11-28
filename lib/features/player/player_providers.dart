import 'package:flutter_riverpod/flutter_riverpod.dart';

class IsFullscreen extends Notifier<bool> {
  @override
  bool build() => false;

  bool toggle() {
    state = !state;
    return state;
  }

  void setFullscreen(bool value) {
    state = value;
  }
}

final isFullscreenProvider = NotifierProvider<IsFullscreen, bool>(
  IsFullscreen.new,
);

class ControlsVisibility extends Notifier<bool> {
  @override
  bool build() => true;

  void setVisible(bool value) {
    state = value;
  }
}

final controlsVisibilityProvider = NotifierProvider<ControlsVisibility, bool>(
  ControlsVisibility.new,
);

/// Tracks whether the desktop application window is currently hidden/minimized.
class AppWindowHidden extends Notifier<bool> {
  @override
  bool build() => false;

  void setHidden(bool hidden) {
    if (state != hidden) state = hidden;
  }
}

final appWindowHiddenProvider = NotifierProvider<AppWindowHidden, bool>(
  AppWindowHidden.new,
);
