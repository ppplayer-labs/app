import 'package:flutter/widgets.dart';

/// Uses only the current frame's insets, including edges that became zero after
/// rotation. iOS view padding survives temporary system UI/keyboard changes.
EdgeInsets currentSafeAreaPadding(
  MediaQueryData mediaQuery, {
  required bool preserveViewPadding,
}) => preserveViewPadding ? mediaQuery.viewPadding : mediaQuery.padding;
