import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimensions.dart';
import '../../features/compressor/presentation/design_system/design_system.dart';
import '../../l10n/app_localizations.dart';
import '../routing/app_routes.dart';

/// The Phase 6 adaptive application shell around destination content.
class MainNavigationShell extends StatelessWidget {
  /// Creates the adaptive navigation shell.
  const MainNavigationShell({
    required this.currentLocation,
    required this.child,
    super.key,
  });

  /// Current router location used to keep navigation selection in sync.
  final String currentLocation;

  /// The active destination content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = AppRoutes.indexForLocation(currentLocation);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide =
            constraints.maxWidth >= AppDimensions.navigationRailBreakpoint;
        final Widget content = wide
            ? Row(
                children: <Widget>[
                  _NavigationRail(
                    selectedIndex: selectedIndex,
                    onSelect: (int index) => _goToIndex(context, index),
                    onAbout: () => context.go(AppRoutes.about),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: child),
                ],
              )
            : child;

        if (wide) return content;
        return Column(
          children: <Widget>[
            Expanded(child: content),
            AppBottomNavigation(
              selectedIndex: selectedIndex,
              onDestinationSelected: (int index) => _goToIndex(context, index),
              destinations: _navigationDestinations(context),
            ),
          ],
        );
      },
    );
  }

  static List<AppBottomNavigationDestination> _navigationDestinations(
    BuildContext context,
  ) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return <AppBottomNavigationDestination>[
      AppBottomNavigationDestination(
        tooltip: l10n.home,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: l10n.home,
      ),
      AppBottomNavigationDestination(
        tooltip: l10n.compress,
        icon: Icons.compress_outlined,
        selectedIcon: Icons.compress_rounded,
        label: l10n.compress,
      ),
      AppBottomNavigationDestination(
        tooltip: l10n.history,
        icon: Icons.history_outlined,
        selectedIcon: Icons.history_rounded,
        label: l10n.history,
      ),
      AppBottomNavigationDestination(
        tooltip: l10n.settings,
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        label: l10n.settings,
      ),
    ];
  }

  static void _goToIndex(BuildContext context, int index) {
    const List<AppRoute> routes = <AppRoute>[
      AppRoute.home,
      AppRoute.compression,
      AppRoute.history,
      AppRoute.settings,
    ];
    context.go(AppRoutes.locationFor(routes[index]));
  }
}

/// One destination inside [AppBottomNavigation].
class AppBottomNavigationDestination {
  /// Creates a destination.
  const AppBottomNavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.tooltip,
  });

  /// Unselected icon.
  final IconData icon;

  /// Selected icon.
  final IconData selectedIcon;

  /// Destination label.
  final String label;

  /// Optional tooltip text.
  final String? tooltip;
}

/// A premium custom bottom navigation bar.
///
/// Replaces the default Material [NavigationBar] with a lighter, more refined
/// component: a hairline-separated surface, a pill indicator that sits behind
/// the selected icon, and compact labels that never shout. The bar owns the
/// Android gesture/navigation inset exactly once (the inner 64dp plus the
/// system bottom padding).
class AppBottomNavigation extends StatelessWidget {
  /// Creates the bottom navigation bar.
  const AppBottomNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    super.key,
  });

  /// Currently selected destination index.
  final int selectedIndex;

  /// Called with the tapped destination index.
  final ValueChanged<int> onDestinationSelected;

  /// Available destinations.
  final List<AppBottomNavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: colors.surfaceContainer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // The hairline sits inside the 64dp body so the total bar height
          // stays exactly 64 + system bottom inset.
          Container(
            height: 64,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: .45),
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                for (int index = 0; index < destinations.length; index++)
                  Expanded(
                    child: _BottomNavigationItem(
                      destination: destinations[index],
                      selected: index == selectedIndex,
                      onTap: () => onDestinationSelected(index),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: bottomInset),
        ],
      ),
    );
  }
}

class _BottomNavigationItem extends StatelessWidget {
  const _BottomNavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppBottomNavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected
                    ? colors.secondaryContainer.withValues(alpha: .9)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 22,
                color: selected
                    ? colors.onSecondaryContainer
                    : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? colors.onSurface : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationRail extends StatelessWidget {
  const _NavigationRail({
    required this.selectedIndex,
    required this.onSelect,
    required this.onAbout,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelect,
      labelType: NavigationRailLabelType.all,
      leading: const Padding(
        padding: EdgeInsets.only(
          top: AppDimensions.spacingMd,
          bottom: AppDimensions.spacingLg,
        ),
        child: AppBrandMark(),
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
        child: PopupMenuButton<String>(
          tooltip: AppLocalizations.of(context).moreDestinations,
          onSelected: (String value) {
            if (value == 'about') onAbout();
          },
          itemBuilder: (BuildContext context) {
            final AppLocalizations l10n = AppLocalizations.of(context);
            return <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'about',
                child: ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(l10n.about),
                ),
              ),
            ];
          },
          child: const Padding(
            padding: EdgeInsets.all(AppDimensions.spacingSm),
            child: Icon(Icons.more_horiz_rounded),
          ),
        ),
      ),
      destinations: _navigationRailDestinations(context),
    );
  }

  List<NavigationRailDestination> _navigationRailDestinations(
    BuildContext context,
  ) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return <NavigationRailDestination>[
      NavigationRailDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home_rounded),
        label: Text(l10n.home),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.compress_outlined),
        selectedIcon: const Icon(Icons.compress_rounded),
        label: Text(l10n.compress),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.history_outlined),
        selectedIcon: const Icon(Icons.history_rounded),
        label: Text(l10n.history),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings_rounded),
        label: Text(l10n.settings),
      ),
    ];
  }
}
