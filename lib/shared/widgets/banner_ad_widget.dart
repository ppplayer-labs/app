import 'package:flutter/widgets.dart';

/// Placeholder widget for the temporary ads-free v4.0.2 release.
///
/// Renders zero size and performs no SDK, consent, or network activity.
class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
