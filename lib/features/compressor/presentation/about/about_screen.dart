import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../design_system/design_system.dart';

/// About Comprezza: product identity, version details, legal information, and
/// the platform license page — all surfaced through the shared component
/// language used by Settings.
class AboutScreen extends StatelessWidget {
  /// Creates the About screen.
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: ListView(
        padding: AppDimensions.pageInsets(MediaQuery.sizeOf(context).width),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _AboutHero(),
                  const SizedBox(height: AppSpacing.xl),
                  AppSectionHeader(
                    title: l10n.about,
                    subtitle: l10n.settingsAboutSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSurface(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Column(
                      children: <Widget>[
                        _AboutRow(
                          icon: Icons.compress_rounded,
                          title: l10n.appName,
                          subtitle: l10n.settingsDeveloper,
                        ),
                        _AboutRow(
                          icon: Icons.tag_rounded,
                          title: l10n.settingsVersion,
                          subtitle: AppConstants.appVersion,
                        ),
                        _AboutRow(
                          icon: Icons.build_circle_outlined,
                          title: l10n.settingsBuildNumber,
                          subtitle: AppConstants.appBuildNumber,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppSectionHeader(
                    title: l10n.aboutLegal,
                    subtitle: l10n.settingsPrivacySubtitle,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSurface(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Column(
                      children: <Widget>[
                        _ActionRow(
                          icon: Icons.policy_outlined,
                          title: l10n.settingsPrivacyPolicy,
                          onTap: () => _showInfo(
                            context,
                            l10n.settingsPrivacyPolicy,
                            l10n.settingsPrivacyPolicyDescription,
                          ),
                        ),
                        _ActionRow(
                          icon: Icons.description_outlined,
                          title: l10n.settingsTerms,
                          onTap: () => _showInfo(
                            context,
                            l10n.settingsTerms,
                            l10n.settingsTermsDescription,
                          ),
                        ),
                        _ActionRow(
                          icon: Icons.menu_book_outlined,
                          title: l10n.settingsLicenses,
                          onTap: () => _showLicenses(context),
                        ),
                        _ActionRow(
                          icon: Icons.code_rounded,
                          title: l10n.settingsOpenSource,
                          onTap: () => _showInfo(
                            context,
                            l10n.settingsOpenSource,
                            l10n.settingsOpenSourceDescription,
                          ),
                        ),
                        _ActionRow(
                          icon: Icons.handshake_outlined,
                          title: l10n.settingsAcknowledgements,
                          onTap: () => _showInfo(
                            context,
                            l10n.settingsAcknowledgements,
                            l10n.settingsAcknowledgementsDescription,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppSectionHeader(title: l10n.settingsAbout),
                  const SizedBox(height: AppSpacing.md),
                  AppSurface(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Column(
                      children: <Widget>[
                        _ActionRow(
                          icon: Icons.language_rounded,
                          title: l10n.settingsWebsite,
                          onTap: () =>
                              _openLink(context, AppConstants.websiteUrl),
                        ),
                        _ActionRow(
                          icon: Icons.star_outline_rounded,
                          title: l10n.settingsRateApp,
                          onTap: () =>
                              _openLink(context, AppConstants.playStoreUrl),
                        ),
                        _ActionRow(
                          icon: Icons.article_outlined,
                          title: l10n.settingsChangelog,
                          onTap: () => _showInfo(
                            context,
                            l10n.settingsChangelog,
                            l10n.settingsChangelogDescription,
                          ),
                        ),
                        _ActionRow(
                          icon: Icons.share_outlined,
                          title: l10n.settingsShareApp,
                          onTap: () => _shareApp(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Text(
                      l10n.privateProcessing,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context, String title, String message) =>
      showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context).close),
            ),
          ],
        ),
      );

  Future<void> _openLink(BuildContext context, String url) async {
    try {
      final bool opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!context.mounted || opened) return;
    } catch (_) {
      if (!context.mounted) return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).genericError),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showLicenses(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    showLicensePage(
      context: context,
      applicationName: l10n.appName,
      applicationVersion: AppConstants.appVersion,
    );
  }

  Future<void> _shareApp(BuildContext context) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    try {
      final ShareResult result = await SharePlus.instance.share(
        ShareParams(
          text: '${l10n.appName} — ${l10n.appTagline}',
          subject: AppConstants.appName,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
      if (!context.mounted) return;
      if (result.status == ShareResultStatus.dismissed ||
          result.status == ShareResultStatus.success) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.settingsExportFailed),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.settingsExportFailed),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

class _AboutHero extends StatelessWidget {
  const _AboutHero();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppSurface(
      padding: AppSpacing.card,
      child: Column(
        children: <Widget>[
          const AppBrandMark(size: 72),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.appName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.appTagline,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: .12),
              borderRadius: AppRadii.pillRadius,
              border: Border.all(color: colors.primary.withValues(alpha: .22)),
            ),
            child: Text(
              '${l10n.settingsVersion} ${AppConstants.appVersion} '
              '(${AppConstants.appBuildNumber})',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) =>
      AppSettingsRow(icon: icon, title: title, description: subtitle);
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppSettingsRow(
      icon: icon,
      title: title,
      onTap: onTap,
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 22,
        color: colors.onSurfaceVariant,
      ),
    );
  }
}
