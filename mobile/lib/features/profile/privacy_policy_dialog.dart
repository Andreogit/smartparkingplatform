import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';

const _googlePrivacyUrl = 'https://policies.google.com/privacy';
const _googleMapsTermsUrl = 'https://cloud.google.com/maps-platform/terms';

Future<void> showPrivacyPolicyDialog(BuildContext context, L10n t) {
  final theme = Theme.of(context);
  final linkStyle = theme.textTheme.bodyMedium?.copyWith(
    color: theme.colorScheme.primary,
    decoration: TextDecoration.underline,
  );

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t.privacyPolicyTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.privacyPolicyIntro, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text(
              t.privacyPolicyDataHeading,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(t.privacyPolicyDataBody, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text(
              t.privacyPolicyGoogleHeading,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(t.privacyPolicyGoogleBody, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text(t.privacyPolicyDisclaimer, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                InkWell(
                  onTap: () => _openExternal(ctx, t, _googlePrivacyUrl),
                  child: Text(t.privacyPolicyLinkGooglePrivacy, style: linkStyle),
                ),
                InkWell(
                  onTap: () => _openExternal(ctx, t, _googleMapsTermsUrl),
                  child: Text(t.privacyPolicyLinkGoogleMapsTerms, style: linkStyle),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.close)),
      ],
    ),
  );
}

Future<void> _openExternal(BuildContext context, L10n t, String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.couldNotOpenLink)),
    );
  }
}
