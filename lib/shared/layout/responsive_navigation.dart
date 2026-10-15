import 'package:flutter/material.dart';

/// Phones keep their navigation and search input when rotated. Desktop windows
/// still choose navigation by width, including short windows.
bool usesWideNavigation(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final platform = Theme.of(context).platform;
  final isMobile =
      platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  return (isMobile ? size.shortestSide : size.width) >= 600;
}
