import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const playerTransitionDuration = Duration(milliseconds: 300);

/// Shares the route's clock with the persistent video surface in the shell.
final playerRouteTransitionProvider = Provider<PlayerRouteTransition>((ref) {
  final transition = PlayerRouteTransition();
  ref.onDispose(transition.dispose);
  return transition;
});

class PlayerRouteTransition extends ChangeNotifier {
  Animation<double>? _animation;
  bool _disposed = false;

  bool get isAttached => _animation != null;
  double get progress => Curves.easeOutQuart.transform(_animation?.value ?? 0);
  AnimationStatus? get status => _animation?.status;

  void attach(Animation<double> animation) {
    if (identical(animation, _animation)) return;
    _animation?.removeListener(_tick);
    _animation?.removeStatusListener(_onStatus);
    _animation = animation;
    animation.addListener(_tick);
    animation.addStatusListener(_onStatus);
    // The route builder runs during build; wake the shell after layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed && identical(_animation, animation)) notifyListeners();
    });
  }

  void detach(Animation<double> animation) {
    if (!identical(animation, _animation)) return;
    animation.removeListener(_tick);
    animation.removeStatusListener(_onStatus);
    _animation = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed && _animation == null) notifyListeners();
    });
  }

  void _tick() => notifyListeners();
  void _onStatus(AnimationStatus status) => notifyListeners();

  @override
  void dispose() {
    _disposed = true;
    _animation?.removeListener(_tick);
    _animation?.removeStatusListener(_onStatus);
    _animation = null;
    super.dispose();
  }
}

class PlayerRouteTransitionBoundary extends ConsumerStatefulWidget {
  const PlayerRouteTransitionBoundary({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  ConsumerState<PlayerRouteTransitionBoundary> createState() =>
      _PlayerRouteTransitionBoundaryState();
}

class _PlayerRouteTransitionBoundaryState
    extends ConsumerState<PlayerRouteTransitionBoundary> {
  late PlayerRouteTransition _transition;

  @override
  void initState() {
    super.initState();
    _transition = ref.read(playerRouteTransitionProvider);
    _transition.attach(widget.animation);
  }

  @override
  void didUpdateWidget(PlayerRouteTransitionBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    _transition.attach(widget.animation);
  }

  @override
  void dispose() {
    _transition.detach(widget.animation);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    alwaysIncludeSemantics: true,
    opacity: widget.animation.drive(
      CurveTween(curve: const Interval(0.35, 1, curve: Curves.easeOut)),
    ),
    // Scope OverlayPortal children (e.g. Material Slider's always-shown value
    // indicator and Tooltips) inside this route's Offstage boundary so
    // HeroController's frame-1 offstage layout cannot orphan traversal children
    // in the ancestor Navigator's Overlay and break Windows ui::AXTree.
    child: Overlay.wrap(child: widget.child),
  );
}
