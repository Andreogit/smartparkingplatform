import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';

class NavigationTarget {
  const NavigationTarget({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

Uri googleMapsDirectionsUri({
  required NavigationTarget destination,
  NavigationTarget? origin,
}) {
  final params = <String, String>{
    'api': '1',
    'destination': '${destination.latitude},${destination.longitude}',
    'travelmode': 'driving',
  };
  if (origin != null) {
    params['origin'] = '${origin.latitude},${origin.longitude}';
  }
  return Uri.https('www.google.com', '/maps/dir/', params);
}

Uri appleMapsDirectionsUri({
  required NavigationTarget destination,
  NavigationTarget? origin,
}) {
  final params = <String, String>{
    'daddr': '${destination.latitude},${destination.longitude}',
  };
  if (origin != null) {
    params['saddr'] = '${origin.latitude},${origin.longitude}';
  }
  return Uri(scheme: 'https', host: 'maps.apple.com', queryParameters: params);
}

Uri wazeNavigateUri({required NavigationTarget destination}) {
  return Uri.https(
    'waze.com',
    '/ul',
    {
      'll': '${destination.latitude},${destination.longitude}',
      'navigate': 'yes',
    },
  );
}

Future<bool> openNavigationUri(Uri uri) async {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

class NavigationAppsRow extends StatelessWidget {
  const NavigationAppsRow({
    super.key,
    required this.l10n,
    required this.destination,
    this.origin,
  });

  final L10n l10n;
  final NavigationTarget destination;
  final NavigationTarget? origin;

  Future<void> _open(BuildContext context, Uri uri) async {
    final opened = await openNavigationUri(uri);
    if (!context.mounted) {
      return;
    }
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotOpenNavigationApp)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.openRouteIn,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _NavAppTile(
                label: 'Google Maps',
                icon: Icons.map_rounded,
                color: const Color(0xFF4285F4),
                onTap: () => _open(
                  context,
                  googleMapsDirectionsUri(
                    destination: destination,
                    origin: origin,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NavAppTile(
                label: 'Apple Maps',
                icon: Icons.map_outlined,
                color: scheme.primary,
                onTap: () => _open(context, appleMapsDirectionsUri(
                  destination: destination,
                  origin: origin,
                )),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NavAppTile(
                label: 'Waze',
                icon: Icons.navigation_rounded,
                color: const Color(0xFF33CCFF),
                onTap: () => _open(
                  context,
                  wazeNavigateUri(destination: destination),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NavAppTile extends StatelessWidget {
  const _NavAppTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest.withOpacity(0.45),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
