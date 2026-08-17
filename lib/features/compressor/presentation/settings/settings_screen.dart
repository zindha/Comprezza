import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/application_entities.dart';
import '../../domain/settings/settings_models.dart';
import '../design_system/design_system.dart';
import 'settings_controller.dart';

/// Isolated Phase 10 Settings experience.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.controller, super.key});

  final SettingsController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsController get controller => widget.controller;
  bool _errorNotificationScheduled = false;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onChanged);
    if (!controller.hasLoaded) controller.load();
  }

  @override
  void dispose() {
    controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    final SettingsControllerError? error = controller.state.error;
    if (error != null && !_errorNotificationScheduled) {
      _errorNotificationScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        controller.clearError();
        _errorNotificationScheduled = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(error, AppLocalizations.of(context))),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  String _errorMessage(SettingsControllerError error, AppLocalizations l10n) =>
      switch (error) {
        SettingsControllerError.loadFailed => l10n.settingsLoadFailed,
        SettingsControllerError.saveFailed => l10n.settingsSaveFailed,
        SettingsControllerError.exportFailed => l10n.settingsExportFailed,
        SettingsControllerError.importFailed => l10n.settingsImportFailed,
        SettingsControllerError.storageActionFailed =>
          l10n.settingsStorageActionFailed,
      };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        // Explicit leading back control: pops when this screen was pushed,
        // otherwise returns to the home destination.
        leading: BackButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).maybePop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Text(l10n.settings),
        actions: <Widget>[
          ListenableBuilder(
            listenable: controller,
            builder: (BuildContext context, Widget? child) => IconButton(
              tooltip: l10n.settingsExport,
              onPressed: controller.state.isExporting ? null : _export,
              icon: const Icon(Icons.ios_share_rounded),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? child) {
          if (controller.state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double horizontal = AppDimensions.pageHorizontal(
                constraints.maxWidth,
              );
              return ListView(
                key: const ValueKey<String>('settings-list'),
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  AppDimensions.spacingSm,
                  horizontal,
                  48,
                ),
                children: <Widget>[
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: _SettingsContent(
                        controller: controller,
                        onExport: _export,
                        onShareApp: _shareApp,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _shareApp() async {
    if (!mounted) return;
    try {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      final ShareResult result = await SharePlus.instance.share(
        ShareParams(
          text:
              '${AppLocalizations.of(context).appName} — ${AppLocalizations.of(context).appTagline}',
          subject: AppConstants.appName,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
      if (!mounted || result.status == ShareResultStatus.success) return;
      if (result.status == ShareResultStatus.dismissed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).settingsExportFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).settingsExportFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _export() async {
    final String? data = await controller.exportSettings();
    if (!mounted || data == null) return;
    try {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      final ShareResult result = await SharePlus.instance.share(
        ShareParams(
          text: data,
          subject: AppLocalizations.of(context).settingsExportConfiguration,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
      if (!mounted || result.status == ShareResultStatus.success) {
        if (mounted && result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).settingsExportReady),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      if (result.status == ShareResultStatus.dismissed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).settingsExportFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).settingsExportFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({
    required this.controller,
    required this.onExport,
    required this.onShareApp,
  });

  final SettingsController controller;
  final Future<void> Function() onExport;
  final Future<void> Function() onShareApp;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SettingsPreferences p = controller.state.preferences;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _SettingsHero(),
        if (controller.state.recommendations.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppDimensions.spacingLg),
          _RecommendationsCard(
            recommendations: controller.state.recommendations,
          ),
        ],
        const SizedBox(height: AppDimensions.spacingLg),
        _SettingsSection(
          icon: Icons.tune_rounded,
          title: l10n.settingsGeneral,
          subtitle: l10n.settingsGeneralSubtitle,
          initiallyExpanded: true,
          childrenBuilder: () => <Widget>[
            // Theme is intentionally not exposed here: Comprezza's identity is
            // the fixed brand palette, so there is no accent/theme picker.
            _ValueRow<SettingsResizeMode>(
              icon: Icons.aspect_ratio_rounded,
              title: l10n.settingsResizeMode,
              value: p.resizeMode,
              values: SettingsResizeMode.values,
              label: _resizeLabel,
              onChanged: (SettingsResizeMode value) =>
                  controller.update(p.copyWith(resizeMode: value)),
            ),
            _SwitchRow(
              icon: Icons.auto_mode_rounded,
              title: l10n.settingsAutoAnalyze,
              value: p.autoAnalyzeImages,
              onChanged: (bool value) =>
                  controller.update(p.copyWith(autoAnalyzeImages: value)),
            ),
            _SwitchRow(
              icon: Icons.lightbulb_outline_rounded,
              title: l10n.settingsAutoRecommend,
              value: p.autoRecommendCompression,
              onChanged: (bool value) => controller.update(
                p.copyWith(autoRecommendCompression: value),
              ),
            ),
            _SwitchRow(
              icon: Icons.history_toggle_off_rounded,
              title: l10n.settingsRememberLast,
              value: p.rememberLastUsedSettings,
              onChanged: (bool value) => controller.update(
                p.copyWith(rememberLastUsedSettings: value),
              ),
            ),
            _SwitchRow(
              icon: Icons.launch_rounded,
              title: l10n.settingsOpenLastScreen,
              value: p.openLastScreen,
              onChanged: (bool value) =>
                  controller.update(p.copyWith(openLastScreen: value)),
            ),
          ],
        ),
        _SettingsSection(
          icon: Icons.compress_rounded,
          title: l10n.settingsCompression,
          subtitle: l10n.settingsCompressionSubtitle,
          childrenBuilder: () => <Widget>[
            _ValueRow<CompressionAlgorithm>(
              icon: Icons.tune_rounded,
              title: l10n.settingsAlgorithm,
              value: p.preferredAlgorithm,
              values: CompressionAlgorithm.values,
              label: _algorithmLabel,
              onChanged: (CompressionAlgorithm value) =>
                  controller.update(p.copyWith(preferredAlgorithm: value)),
            ),
            _PresetRow(
              value: p.defaultPreset,
              onChanged: (String value) =>
                  controller.update(p.copyWith(defaultPreset: value)),
            ),
            _QualityRow(
              value: p.compressionQuality,
              onChanged: (int value) =>
                  controller.update(p.copyWith(compressionQuality: value)),
            ),
            _ValueRow<ImageFormat>(
              icon: Icons.insert_drive_file_outlined,
              title: l10n.settingsOutputFormat,
              value: p.defaultFormat,
              values: const <ImageFormat>[
                ImageFormat.jpeg,
                ImageFormat.png,
                ImageFormat.webp,
              ],
              label: _formatLabel,
              onChanged: (ImageFormat value) =>
                  controller.update(p.copyWith(defaultFormat: value)),
            ),
            _TargetSizeRow(
              value: p.defaultTargetFileSizeKb,
              onChanged: (int? value) => controller.update(
                value == null
                    ? p.copyWith(clearDefaultTargetFileSize: true)
                    : p.copyWith(defaultTargetFileSizeKb: value),
              ),
            ),
            _SwitchRow(
              icon: Icons.compress_rounded,
              title: l10n.settingsTargetByDefault,
              value: p.compressToTargetSizeByDefault,
              onChanged: (bool value) => controller.update(
                p.copyWith(compressToTargetSizeByDefault: value),
              ),
            ),
            // Keep and remove are mutually exclusive: enabling one disables
            // the other so both switches always respond to the user.
            _SwitchRow(
              icon: Icons.data_object_rounded,
              title: l10n.settingsKeepMetadata,
              value: p.alwaysKeepMetadata,
              onChanged: (bool value) => controller.update(
                p.copyWith(
                  alwaysKeepMetadata: value,
                  alwaysRemoveMetadata: value ? false : p.alwaysRemoveMetadata,
                ),
              ),
            ),
            _SwitchRow(
              icon: Icons.hide_source_outlined,
              title: l10n.settingsRemoveMetadata,
              value: p.alwaysRemoveMetadata,
              onChanged: (bool value) => controller.update(
                p.copyWith(
                  alwaysRemoveMetadata: value,
                  alwaysKeepMetadata: value ? false : p.alwaysKeepMetadata,
                ),
              ),
            ),
            _AdvancedGroup(
              children: <Widget>[
                _SwitchRow(
                  icon: Icons.preview_outlined,
                  title: l10n.settingsQualityPreview,
                  value: p.qualityPreview,
                  onChanged: (bool value) =>
                      controller.update(p.copyWith(qualityPreview: value)),
                ),
                _SwitchRow(
                  icon: Icons.auto_graph_rounded,
                  title: l10n.settingsSmartRecommendations,
                  value: p.enableSmartRecommendations,
                  onChanged: (bool value) => controller.update(
                    p.copyWith(enableSmartRecommendations: value),
                  ),
                ),
                _SwitchRow(
                  icon: Icons.speed_rounded,
                  title: l10n.settingsLiveEstimate,
                  value: p.enableLiveSizeEstimation,
                  onChanged: (bool value) => controller.update(
                    p.copyWith(enableLiveSizeEstimation: value),
                  ),
                ),
                _SwitchRow(
                  icon: Icons.query_stats_rounded,
                  title: l10n.settingsBenchmark,
                  value: p.enableCompressionBenchmark,
                  onChanged: (bool value) => controller.update(
                    p.copyWith(enableCompressionBenchmark: value),
                  ),
                ),
              ],
            ),
          ],
        ),
        _SettingsSection(
          icon: Icons.folder_copy_outlined,
          title: l10n.settingsStorage,
          subtitle: l10n.settingsStorageSubtitle,
          initiallyExpanded: true,
          childrenBuilder: () => <Widget>[
            _SwitchRow(
              icon: Icons.cleaning_services_outlined,
              title: l10n.settingsAutoDeleteTemporary,
              value: p.autoDeleteTemporaryFiles,
              onChanged: (bool value) => controller.update(
                p.copyWith(autoDeleteTemporaryFiles: value),
              ),
            ),
            _ValueRow<CleanupInterval>(
              icon: Icons.schedule_rounded,
              title: l10n.settingsCleanupInterval,
              value: p.cleanupInterval,
              values: CleanupInterval.values,
              label: _cleanupLabel,
              onChanged: (CleanupInterval value) =>
                  controller.update(p.copyWith(cleanupInterval: value)),
            ),
            _SwitchRow(
              icon: Icons.history_rounded,
              title: l10n.settingsAutoDeleteOldHistory,
              value: p.autoDeleteOldHistory,
              onChanged: (bool value) =>
                  controller.update(p.copyWith(autoDeleteOldHistory: value)),
            ),
            _SliderRow(
              icon: Icons.storage_rounded,
              title: l10n.settingsMaximumCache,
              value: p.maximumCacheSizeMb.toDouble(),
              min: 32,
              max: 1024,
              divisions: 31,
              labelBuilder: (double value) =>
                  l10n.settingsMegabytesValue(value.round()),
              onChanged: (double value) => controller.update(
                p.copyWith(maximumCacheSizeMb: value.round()),
              ),
            ),
            _SliderRow(
              icon: Icons.list_alt_rounded,
              title: l10n.settingsHistorySizeLimit,
              value: p.compressionHistorySizeLimit.toDouble(),
              min: 50,
              max: 2000,
              divisions: 39,
              labelBuilder: (double value) =>
                  l10n.settingsItemsValue(value.round()),
              onChanged: (double value) => controller.update(
                p.copyWith(compressionHistorySizeLimit: value.round()),
              ),
            ),
            _StorageUsageTile(usage: controller.state.storageUsage),
            _ActionRow(
              icon: Icons.delete_sweep_outlined,
              title: l10n.settingsClearCache,
              onTap: () => _confirmAction(
                context,
                l10n.settingsClearCache,
                l10n.settingsClearCacheMessage,
                controller.clearCache,
              ),
            ),
            _ActionRow(
              icon: Icons.history_toggle_off_rounded,
              title: l10n.settingsClearHistory,
              onTap: () => _confirmAction(
                context,
                l10n.settingsClearHistory,
                l10n.settingsClearHistoryMessage,
                controller.clearHistory,
              ),
            ),
            _ActionRow(
              icon: Icons.restart_alt_rounded,
              title: l10n.settingsResetStorage,
              onTap: () => _confirmAction(
                context,
                l10n.settingsResetStorage,
                l10n.settingsResetStorageMessage,
                controller.resetStorage,
                destructive: true,
              ),
            ),
          ],
        ),
        _SettingsSection(
          icon: Icons.dark_mode_outlined,
          title: l10n.settingsAppearance,
          subtitle: l10n.settingsAppearanceSubtitle,
          childrenBuilder: () => <Widget>[
            _SwitchRow(
              icon: Icons.share_rounded,
              title: l10n.settingsAdaptiveIcons,
              value: p.adaptiveIcons,
              onChanged: (bool value) =>
                  controller.update(p.copyWith(adaptiveIcons: value)),
            ),
            _SwitchRow(
              icon: Icons.zoom_in_rounded,
              title: l10n.settingsLargeUi,
              value: p.largeUiMode,
              onChanged: (bool value) => controller.update(
                p.copyWith(
                  largeUiMode: value,
                  compactUiMode: value ? false : p.compactUiMode,
                ),
              ),
            ),
            _SwitchRow(
              icon: Icons.view_compact_outlined,
              title: l10n.settingsCompactUi,
              value: p.compactUiMode,
              onChanged: (bool value) => controller.update(
                p.copyWith(
                  compactUiMode: value,
                  largeUiMode: value ? false : p.largeUiMode,
                ),
              ),
            ),
            _ValueRow<SettingsAnimationSpeed>(
              icon: Icons.animation_rounded,
              title: l10n.settingsAnimationSpeed,
              value: p.animationSpeed,
              values: SettingsAnimationSpeed.values,
              label: _animationLabel,
              onChanged: (SettingsAnimationSpeed value) => controller.update(
                p.copyWith(
                  animationSpeed: value,
                  reduceMotion: value != SettingsAnimationSpeed.full,
                ),
              ),
            ),
            _ValueRow<SettingsDisplayDensity>(
              icon: Icons.density_medium_rounded,
              title: l10n.settingsDisplayDensity,
              value: p.displayDensity,
              values: SettingsDisplayDensity.values,
              label: _densityLabel,
              onChanged: (SettingsDisplayDensity value) =>
                  controller.update(p.copyWith(displayDensity: value)),
            ),
            _SliderRow(
              icon: Icons.format_size_rounded,
              title: l10n.settingsFontScaling,
              value: p.fontScale,
              min: .85,
              max: 1.5,
              divisions: 13,
              labelBuilder: (double value) =>
                  l10n.settingsPercentValue((value * 100).round()),
              onChanged: (double value) =>
                  controller.update(p.copyWith(fontScale: value)),
            ),
          ],
        ),
        _SettingsSection(
          icon: Icons.accessibility_new_rounded,
          title: l10n.settingsAccessibility,
          subtitle: l10n.settingsAccessibilitySubtitle,
          childrenBuilder: () => <Widget>[
            _SwitchRow(
              icon: Icons.record_voice_over_rounded,
              title: l10n.settingsScreenReaders,
              value: p.screenReaders,
              onChanged: (bool value) =>
                  controller.update(p.copyWith(screenReaders: value)),
            ),
            _SwitchRow(
              icon: Icons.contrast_rounded,
              title: l10n.settingsHighContrast,
              value: p.highContrast,
              onChanged: (bool value) =>
                  controller.update(p.copyWith(highContrast: value)),
            ),
            _SwitchRow(
              icon: Icons.touch_app_rounded,
              title: l10n.settingsLargeTouchTargets,
              value: p.largeTouchTargets,
              onChanged: (bool value) =>
                  controller.update(p.copyWith(largeTouchTargets: value)),
            ),
            _SwitchRow(
              icon: Icons.text_fields_rounded,
              title: l10n.settingsDynamicText,
              value: p.dynamicTextScaling,
              onChanged: (bool value) =>
                  controller.update(p.copyWith(dynamicTextScaling: value)),
            ),
            _SwitchRow(
              icon: Icons.campaign_outlined,
              title: l10n.settingsProgressAnnouncements,
              value: p.accessibleProgressAnnouncements,
              onChanged: (bool value) => controller.update(
                p.copyWith(accessibleProgressAnnouncements: value),
              ),
            ),
            _SwitchRow(
              icon: Icons.error_outline_rounded,
              title: l10n.settingsErrorAnnouncements,
              value: p.accessibleErrorAnnouncements,
              onChanged: (bool value) => controller.update(
                p.copyWith(accessibleErrorAnnouncements: value),
              ),
            ),
            _SwitchRow(
              icon: Icons.label_outline_rounded,
              title: l10n.settingsSemanticLabels,
              value: p.semanticLabels,
              onChanged: (bool value) =>
                  controller.update(p.copyWith(semanticLabels: value)),
            ),
            _SwitchRow(
              icon: Icons.motion_photos_off_rounded,
              title: l10n.settingsReduceAnimations,
              value: p.reduceAnimations,
              onChanged: (bool value) =>
                  controller.update(p.copyWith(reduceAnimations: value)),
            ),
            _SwitchRow(
              icon: Icons.palette_outlined,
              title: l10n.settingsColorBlindPalette,
              value: p.colorBlindFriendlyPalette,
              onChanged: (bool value) => controller.update(
                p.copyWith(colorBlindFriendlyPalette: value),
              ),
            ),
          ],
        ),
        _SettingsSection(
          icon: Icons.shield_outlined,
          title: l10n.settingsPrivacy,
          subtitle: l10n.settingsPrivacySubtitle,
          childrenBuilder: () => <Widget>[
            _PrivacyRow(
              icon: Icons.offline_bolt_rounded,
              title: l10n.settingsOfflineProcessing,
            ),
            _PrivacyRow(
              icon: Icons.cloud_off_rounded,
              title: l10n.settingsNoCloudUpload,
            ),
            _PrivacyRow(
              icon: Icons.analytics_outlined,
              title: l10n.settingsNoAnalytics,
            ),
            _PrivacyRow(
              icon: Icons.gps_off_rounded,
              title: l10n.settingsNoTracking,
            ),
            _PrivacyRow(
              icon: Icons.person_off_outlined,
              title: l10n.settingsNoUserAccounts,
            ),
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
              icon: Icons.code_rounded,
              title: l10n.settingsOpenSource,
              onTap: () => _showInfo(
                context,
                l10n.settingsOpenSource,
                l10n.settingsOpenSourceDescription,
              ),
            ),
          ],
        ),
        _SettingsSection(
          icon: Icons.tune_rounded,
          title: l10n.settingsAdvanced,
          subtitle: l10n.settingsAdvancedSubtitle,
          childrenBuilder: () => <Widget>[
            if (!controller.isRelease) ...<Widget>[
              _SwitchRow(
                icon: Icons.speed_rounded,
                title: l10n.settingsBenchmarkMode,
                value: p.benchmarkMode,
                enabled: controller.state.developerOptionsVisible,
                onChanged: (bool value) =>
                    controller.update(p.copyWith(benchmarkMode: value)),
              ),
              _SwitchRow(
                icon: Icons.bug_report_outlined,
                title: l10n.settingsDeveloperLogging,
                value: p.developerLogging,
                enabled: controller.state.developerOptionsVisible,
                onChanged: (bool value) =>
                    controller.update(p.copyWith(developerLogging: value)),
              ),
              _SwitchRow(
                icon: Icons.subject_rounded,
                title: l10n.settingsVerboseLogging,
                value: p.verboseLogging,
                enabled: controller.state.developerOptionsVisible,
                onChanged: (bool value) =>
                    controller.update(p.copyWith(verboseLogging: value)),
              ),
            ],
            _ActionRow(
              icon: Icons.file_download_outlined,
              title: l10n.settingsExportConfiguration,
              onTap: onExport,
            ),
            _ActionRow(
              icon: Icons.file_upload_outlined,
              title: l10n.settingsImportConfiguration,
              onTap: () => _importFromClipboard(context),
            ),
            _ActionRow(
              icon: Icons.restart_alt_rounded,
              title: l10n.settingsFactoryReset,
              destructive: true,
              onTap: () => _confirmAction(
                context,
                l10n.settingsFactoryReset,
                l10n.settingsFactoryResetMessage,
                controller.factoryReset,
                destructive: true,
              ),
            ),
          ],
        ),
        _SettingsSection(
          icon: Icons.info_outline_rounded,
          title: l10n.settingsAbout,
          subtitle: l10n.settingsAboutSubtitle,
          childrenBuilder: () => <Widget>[
            _AboutRow(
              title: l10n.appName,
              subtitle: l10n.settingsDeveloper,
              icon: Icons.compress_rounded,
            ),
            _AboutRow(
              title: l10n.settingsVersion,
              subtitle: AppConstants.appVersion,
              icon: Icons.tag_rounded,
              onTap: () => controller.tapVersion(),
            ),
            _AboutRow(
              title: l10n.settingsBuildNumber,
              subtitle: AppConstants.appBuildNumber,
              icon: Icons.build_circle_outlined,
            ),
            _ActionRow(
              icon: Icons.language_rounded,
              title: l10n.settingsWebsite,
              onTap: () => _openLink(context, AppConstants.websiteUrl),
            ),
            _ActionRow(
              icon: Icons.star_outline_rounded,
              title: l10n.settingsRateApp,
              onTap: () => _openLink(context, AppConstants.playStoreUrl),
            ),
            _ActionRow(
              icon: Icons.share_outlined,
              title: l10n.settingsShareApp,
              onTap: onShareApp,
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
        if (controller.state.developerOptionsVisible && !controller.isRelease)
          _SettingsSection(
            icon: Icons.developer_mode_rounded,
            title: l10n.settingsDeveloperOptions,
            subtitle: l10n.settingsDeveloperOptionsSubtitle,
            childrenBuilder: () => <Widget>[
              _StatusRow(
                title: l10n.settingsViewEngineStatus,
                value: l10n.settingsStatusReady,
              ),
              _StatusRow(
                title: l10n.settingsViewQueueStatus,
                value: l10n.settingsStatusIdle,
              ),
              _StatusRow(
                title: l10n.settingsViewCacheStatus,
                value: l10n.settingsStatusProtected,
              ),
              _StatusRow(
                title: l10n.settingsPerformanceMonitor,
                value: l10n.settingsStatusLocalOnly,
              ),
              _StatusRow(
                title: l10n.settingsFrameStatistics,
                value: l10n.settingsStatusDebugOnly,
              ),
              _StatusRow(
                title: l10n.settingsMemoryStatistics,
                value: l10n.settingsStatusDebugOnly,
              ),
              _StatusRow(
                title: l10n.settingsDependencyGraph,
                value: l10n.settingsStatusDebugOnly,
              ),
              _StatusRow(
                title: l10n.settingsCompressionBenchmark,
                value: l10n.settingsStatusDebugOnly,
              ),
              _StatusRow(
                title: l10n.settingsExperimentalFeatures,
                value: l10n.settingsStatusDebugOnly,
              ),
              _StatusRow(
                title: l10n.settingsFeatureFlags,
                value: l10n.settingsStatusDebugOnly,
              ),
            ],
          ),
        _ResetRow(
          onResetAppearance: () => _confirmAction(
            context,
            l10n.settingsResetAppearance,
            l10n.settingsResetAppearanceMessage,
            controller.resetAppearance,
          ),
          onResetCompression: () => _confirmAction(
            context,
            l10n.settingsResetCompression,
            l10n.settingsResetCompressionMessage,
            controller.resetCompression,
          ),
          onResetRecommendations: () => _confirmAction(
            context,
            l10n.settingsResetRecommendations,
            l10n.settingsResetRecommendationsMessage,
            controller.resetRecommendations,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAction(
    BuildContext context,
    String title,
    String message,
    Future<void> Function() action, {
    bool destructive = false,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              destructive
                  ? AppLocalizations.of(context).settingsReset
                  : AppLocalizations.of(context).settingsConfirm,
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await action();
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
      ),
    );
  }

  Future<void> _importFromClipboard(BuildContext context) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ClipboardData? clipboard = await Clipboard.getData(
      Clipboard.kTextPlain,
    );
    if (!context.mounted) return;
    final String? encoded = clipboard?.text;
    if (encoded == null ||
        encoded.trim().isEmpty ||
        encoded.length > 256 * 1024) {
      _showInfo(
        context,
        l10n.settingsImportConfiguration,
        l10n.settingsImportDescription,
      );
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.settingsImportConfiguration),
        content: Text(l10n.settingsImportDescription),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.settingsConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await controller.importSettings(encoded);
    if (!context.mounted) return;
    final bool importFailed = controller.state.error != null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          importFailed
              ? l10n.settingsImportFailed
              : l10n.settingsImportConfiguration,
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: importFailed ? 4 : 3),
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

  String _resizeLabel(SettingsResizeMode value, AppLocalizations l10n) =>
      switch (value) {
        SettingsResizeMode.original => l10n.settingsOriginalResize,
        SettingsResizeMode.percentage75 => l10n.resize75,
        SettingsResizeMode.percentage50 => l10n.resize50,
        SettingsResizeMode.percentage25 => l10n.resize25,
      };

  String _algorithmLabel(CompressionAlgorithm value, AppLocalizations l10n) =>
      switch (value) {
        CompressionAlgorithm.automatic => l10n.settingsAutomatic,
        CompressionAlgorithm.jpeg => l10n.jpegFormat,
        CompressionAlgorithm.png => l10n.pngFormat,
        CompressionAlgorithm.webp => l10n.webpFormat,
      };

  String _formatLabel(ImageFormat value, AppLocalizations l10n) =>
      switch (value) {
        ImageFormat.jpeg => l10n.jpegFormat,
        ImageFormat.png => l10n.pngFormat,
        ImageFormat.webp => l10n.webpFormat,
        _ => value.name.toUpperCase(),
      };

  String _cleanupLabel(CleanupInterval value, AppLocalizations l10n) =>
      switch (value) {
        CleanupInterval.never => l10n.settingsNever,
        CleanupInterval.daily => l10n.settingsDaily,
        CleanupInterval.weekly => l10n.settingsWeekly,
        CleanupInterval.monthly => l10n.settingsMonthly,
      };

  String _animationLabel(SettingsAnimationSpeed value, AppLocalizations l10n) =>
      switch (value) {
        SettingsAnimationSpeed.full => l10n.settingsFullMotion,
        SettingsAnimationSpeed.reduced => l10n.settingsReducedMotion,
        SettingsAnimationSpeed.off => l10n.settingsMotionOff,
      };

  String _densityLabel(SettingsDisplayDensity value, AppLocalizations l10n) =>
      switch (value) {
        SettingsDisplayDensity.comfortable => l10n.settingsComfortableDensity,
        SettingsDisplayDensity.compact => l10n.settingsCompactDensity,
      };
}

/// Compact, card-free brand header: mark, name, one quiet line — then the
/// sections start immediately. Nothing here pretends to be a setting.
class _SettingsHero extends StatelessWidget {
  const _SettingsHero();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      // Keep the group label exact instead of merging it with the child text,
      // so screen readers announce the overview label on its own.
      explicitChildNodes: true,
      label: l10n.settingsHeroSemantic,
      child: Row(
        children: <Widget>[
          const AppBrandMark(size: 40),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.settingsHeroTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.settingsHeroSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard({required this.recommendations});

  final List<SettingsRecommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 20,
                color: colors.primary,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Text(
                l10n.settingsRecommendations,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          ...recommendations.map(
            (SettingsRecommendation recommendation) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _recommendationIcon(recommendation.kind),
                color: colors.primary,
              ),
              title: Text(_recommendationTitle(recommendation.kind, l10n)),
              subtitle: Text(
                _recommendationMessage(recommendation.kind, l10n),
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _recommendationIcon(
    SettingsRecommendationKind kind,
  ) => switch (kind) {
    SettingsRecommendationKind.largeCache => Icons.cleaning_services_outlined,
    SettingsRecommendationKind.screenshots => Icons.screenshot_monitor_outlined,
    SettingsRecommendationKind.photos => Icons.photo_outlined,
    SettingsRecommendationKind.websiteImages => Icons.language_outlined,
    SettingsRecommendationKind.lowStorage => Icons.storage_rounded,
  };

  String _recommendationTitle(
    SettingsRecommendationKind kind,
    AppLocalizations l10n,
  ) => switch (kind) {
    SettingsRecommendationKind.largeCache =>
      l10n.settingsRecommendationLargeCache,
    SettingsRecommendationKind.screenshots =>
      l10n.settingsRecommendationScreenshots,
    SettingsRecommendationKind.photos => l10n.settingsRecommendationPhotos,
    SettingsRecommendationKind.websiteImages =>
      l10n.settingsRecommendationWebsite,
    SettingsRecommendationKind.lowStorage =>
      l10n.settingsRecommendationLowStorage,
  };

  String _recommendationMessage(
    SettingsRecommendationKind kind,
    AppLocalizations l10n,
  ) => switch (kind) {
    SettingsRecommendationKind.largeCache =>
      l10n.settingsRecommendationLargeCacheMessage,
    SettingsRecommendationKind.screenshots =>
      l10n.settingsRecommendationScreenshotsMessage,
    SettingsRecommendationKind.photos =>
      l10n.settingsRecommendationPhotosMessage,
    SettingsRecommendationKind.websiteImages =>
      l10n.settingsRecommendationWebsiteMessage,
    SettingsRecommendationKind.lowStorage =>
      l10n.settingsRecommendationLowStorageMessage,
  };
}

/// A grouped settings section: a labeled, expandable surface with a consistent
/// row language inside. Sections stay visually distinct from one another
/// instead of melting into one giant container.
/// Progressive disclosure for power-user compression toggles so everyday
/// defaults stay visible and advanced controls are one tap away.
class _AdvancedGroup extends StatefulWidget {
  const _AdvancedGroup({required this.children});

  final List<Widget> children;

  @override
  State<_AdvancedGroup> createState() => _AdvancedGroupState();
}

class _AdvancedGroupState extends State<_AdvancedGroup> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spacingMd),
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            onExpansionChanged: (bool value) =>
                setState(() => _expanded = value),
            minTileHeight: 56,
            leading: Icon(Icons.tune_rounded, size: 20, color: colors.primary),
            title: Text(
              l10n.settingsAdvanced,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            tilePadding: const EdgeInsets.symmetric(vertical: 4),
            childrenPadding: const EdgeInsets.only(top: 4),
            shape: const Border(),
            collapsedShape: const Border(),
            children: _expanded ? widget.children : const <Widget>[],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatefulWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.childrenBuilder,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> Function() childrenBuilder;
  final bool initiallyExpanded;

  @override
  State<_SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<_SettingsSection> {
  late bool _expanded;
  List<Widget>? _children;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    if (_expanded) _children = widget.childrenBuilder();
  }

  @override
  void didUpdateWidget(covariant _SettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_expanded) _children = widget.childrenBuilder();
  }

  void _onExpansionChanged(bool expanded) {
    if (!mounted) return;
    setState(() {
      _expanded = expanded;
      _children = expanded ? widget.childrenBuilder() : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spacingMd),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: widget.initiallyExpanded,
            onExpansionChanged: _onExpansionChanged,
            minTileHeight: 64,
            leading: AppIconBox(icon: widget.icon),
            title: Text(
              widget.title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              widget.subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            children: _expanded
                ? (_children ?? const <Widget>[])
                : const <Widget>[],
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSettingsRow(
      icon: icon,
      title: title,
      trailing: Switch(value: value, onChanged: enabled ? onChanged : null),
      onTap: enabled ? () => onChanged(!value) : null,
    );
  }
}

class _ValueRow<T> extends StatelessWidget {
  const _ValueRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final T value;
  final List<T> values;
  final String Function(T value, AppLocalizations l10n) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<AppValueOption<T>> options = values
        .map(
          (T item) => AppValueOption<T>(value: item, label: label(item, l10n)),
        )
        .toList(growable: false);
    return AppSettingsRow(
      icon: icon,
      title: title,
      trailing: AppValueSelector<T>(
        value: value,
        options: options,
        title: title,
        icon: icon,
        onSelected: onChanged,
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _ValueRow<String>(
      icon: Icons.bookmark_outline_rounded,
      title: l10n.settingsDefaultPreset,
      value: value,
      values: const <String>['balanced', 'web', 'lossless'],
      label: (String item, AppLocalizations l10n) => switch (item) {
        'balanced' => l10n.settingsBalancedPreset,
        'web' => l10n.settingsWebPreset,
        'lossless' => l10n.settingsLosslessPreset,
        _ => item,
      },
      onChanged: onChanged,
    );
  }
}

class _TargetSizeRow extends StatelessWidget {
  const _TargetSizeRow({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<AppValueOption<int?>> options = <int?>[null, 100, 250, 500, 1024]
        .map(
          (int? item) => AppValueOption<int?>(
            value: item,
            label: item == null
                ? l10n.settingsNoTarget
                : l10n.settingsKilobytesValue(item),
          ),
        )
        .toList(growable: false);
    return AppSettingsRow(
      icon: Icons.data_usage_rounded,
      title: l10n.settingsDefaultTarget,
      trailing: AppValueSelector<int?>(
        value: value,
        options: options,
        title: l10n.settingsDefaultTarget,
        icon: Icons.data_usage_rounded,
        onSelected: onChanged,
      ),
    );
  }
}

class _QualityRow extends StatelessWidget {
  const _QualityRow({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _SliderRow(
      icon: Icons.tune_rounded,
      title: l10n.settingsQuality,
      value: value.toDouble(),
      min: 1,
      max: 100,
      divisions: 99,
      labelBuilder: (double next) => l10n.settingsPercentValue(next.round()),
      onChanged: (double next) => onChanged(next.round()),
    );
  }
}

/// A slider row that keeps its drag value local and commits to the controller
/// only when the drag ends.
///
/// Calling the controller on every `onChanged` tick would notify the whole
/// settings list and queue a persistence write per pixel of movement; holding
/// the value locally keeps the label live while the thumb moves and reduces
/// both rebuilds and disk writes to one per drag.
class _SliderRow extends StatefulWidget {
  const _SliderRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.labelBuilder,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double value) labelBuilder;
  final ValueChanged<double> onChanged;

  @override
  State<_SliderRow> createState() => _SliderRowState();
}

class _SliderRowState extends State<_SliderRow> {
  /// The in-progress drag value, or null when not dragging. Falls back to the
  /// persisted [widget.value] so external changes (reset, import) stay visible.
  double? _dragValue;

  double get _effectiveValue => _dragValue ?? widget.value;

  @override
  void didUpdateWidget(covariant _SliderRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A drag that committed elsewhere (or a reset/import) replaces the local
    // value; otherwise a committed change would snap back on the next build.
    if (oldWidget.value != widget.value) _dragValue = null;
  }

  void _handleChanged(double value) {
    setState(() => _dragValue = value);
  }

  void _handleChangeEnd(double value) {
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double value = _effectiveValue;
    final double clamped = value.clamp(widget.min, widget.max).toDouble();
    final String valueLabel = widget.labelBuilder(clamped);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSettingsRow(
          icon: widget.icon,
          title: widget.title,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: .5),
              ),
            ),
            child: Text(
              valueLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Semantics(
            label: widget.title,
            value: valueLabel,
            child: Slider(
              value: clamped,
              min: widget.min,
              max: widget.max,
              divisions: widget.divisions,
              label: valueLabel,
              semanticFormatterCallback: (_) => valueLabel,
              onChanged: _handleChanged,
              onChangeEnd: _handleChangeEnd,
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color? tone = destructive ? colors.error : null;
    return AppSettingsRow(
      icon: icon,
      title: title,
      tone: tone,
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 22,
        color: destructive ? colors.error : colors.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppSettingsRow(
      icon: icon,
      title: title,
      description: subtitle,
      trailing: onTap == null
          ? null
          : Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: colors.onSurfaceVariant,
            ),
      onTap: onTap,
    );
  }
}

class _PrivacyRow extends StatelessWidget {
  const _PrivacyRow({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final String alwaysOn = AppLocalizations.of(
      context,
    ).settingsPrivacyAlwaysOn;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      readOnly: true,
      label: '$title. $alwaysOn',
      child: ExcludeSemantics(
        child: AppSettingsRow(
          icon: icon,
          title: title,
          description: alwaysOn,
          trailing: Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: colors.tertiary,
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppSettingsRow(
      icon: Icons.monitor_heart_outlined,
      title: title,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: .6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          value,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ResetRow extends StatelessWidget {
  const _ResetRow({
    required this.onResetAppearance,
    required this.onResetCompression,
    required this.onResetRecommendations,
  });

  final VoidCallback onResetAppearance;
  final VoidCallback onResetCompression;
  final VoidCallback onResetRecommendations;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spacingLg),
      child: Wrap(
        spacing: AppDimensions.spacingSm,
        runSpacing: AppDimensions.spacingSm,
        children: <Widget>[
          OutlinedButton.icon(
            onPressed: onResetAppearance,
            icon: const Icon(Icons.palette_outlined),
            label: Text(l10n.settingsResetAppearance),
          ),
          OutlinedButton.icon(
            onPressed: onResetCompression,
            icon: const Icon(Icons.compress_rounded),
            label: Text(l10n.settingsResetCompression),
          ),
          OutlinedButton.icon(
            onPressed: onResetRecommendations,
            icon: const Icon(Icons.lightbulb_outline_rounded),
            label: Text(l10n.settingsResetRecommendations),
          ),
        ],
      ),
    );
  }
}

class _StorageUsageTile extends StatelessWidget {
  const _StorageUsageTile({required this.usage});

  final SettingsStorageUsage usage;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    String size(int bytes) =>
        l10n.settingsMegabytesValue((bytes / (1024 * 1024)).round());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSettingsRow(
          icon: Icons.pie_chart_outline_rounded,
          title: l10n.settingsStorageOverview,
          description: l10n.settingsStorageOverviewValue(
            size(usage.totalBytes),
          ),
        ),
        _UsageRow(
          label: l10n.settingsStorageCache,
          value: size(usage.cacheBytes),
        ),
        _UsageRow(
          label: l10n.settingsStorageTemporary,
          value: size(usage.temporaryBytes),
        ),
        _UsageRow(
          label: l10n.settingsStorageHistory,
          value: size(usage.historyBytes),
        ),
        _UsageRow(
          label: l10n.settingsStorageExports,
          value: size(usage.exportsBytes),
        ),
      ],
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 4, top: 2, bottom: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
