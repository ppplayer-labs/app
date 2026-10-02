import 'package:flutter/material.dart';
import 'package:ppplayer/l10n/app_localizations.dart';

/// Keeps navigation reachable without consuming a full sidebar at narrow widths.
class CompactDesktopNavigation extends StatelessWidget {
  const CompactDesktopNavigation({
    super.key,
    required this.location,
    required this.onNavigate,
  });
  final String location;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final destinations = [
      (path: '/home', label: l10n.home, icon: Icons.home_outlined),
      (path: '/discover', label: l10n.discover, icon: Icons.explore_outlined),
      (path: '/search', label: l10n.search, icon: Icons.search),
      (
        path: '/library',
        label: l10n.library,
        icon: Icons.library_music_outlined,
      ),
      (
        path: '/liked-songs',
        label: l10n.favorites,
        icon: Icons.favorite_outline,
      ),
      (
        path: '/recently-played',
        label: l10n.recentlyPlayed,
        icon: Icons.history,
      ),
    ];
    return Container(
      width: 72,
      color: colors.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Image.asset(
              'assets/logo.png',
              height: 28,
              color: colors.primary,
            ),
          ),
          for (final destination in destinations)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: IconButton(
                tooltip: destination.label,
                isSelected: location.startsWith(destination.path),
                style: IconButton.styleFrom(
                  foregroundColor: colors.onSurfaceVariant,
                  backgroundColor: location.startsWith(destination.path)
                      ? colors.primaryContainer
                      : null,
                ),
                icon: Icon(destination.icon),
                onPressed: () => onNavigate(destination.path),
              ),
            ),
        ],
      ),
    );
  }
}
