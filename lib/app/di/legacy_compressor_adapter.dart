import 'package:flutter/widgets.dart';

import '../../features/compressor/data/services/file_management/interfaces/file_management_interfaces.dart';
import '../../features/compressor/domain/gateways/compressor_gateways.dart';
import '../../features/compressor/presentation/compressor_controller.dart';
import '../../features/compressor/presentation/home_screen.dart';
import '../theme/app_theme_mode.dart';
import 'service_locator.dart';

/// Transitional adapter isolating the pre-hardening compressor surface.
///
/// This adapter exists only until the feature is migrated to Provider-backed
/// state and domain use cases. No new feature logic belongs here.
final class LegacyCompressorAdapter implements Disposable {
  /// Creates an adapter around a controller assembled from domain gateways.
  LegacyCompressorAdapter({
    required ImagePickerGateway pickerGateway,
    required ImageCompressionGateway compressionGateway,
    required ImageExportGateway exportGateway,
    HistoryStorage? history,
    CompressorController? controller,
  }) : _controller =
           controller ??
           CompressorController(
             pickerGateway: pickerGateway,
             compressionGateway: compressionGateway,
             exportGateway: exportGateway,
             history: history,
           );

  final CompressorController _controller;

  /// Builds the preserved prototype screen for the migration period.
  Widget build(
    BuildContext context, {
    required AppThemeMode themeMode,
    required VoidCallback onToggleTheme,
  }) {
    return HomeScreen(
      controller: _controller,
      isDarkMode: themeMode == AppThemeMode.dark,
      onThemeToggle: onToggleTheme,
    );
  }

  /// Releases the legacy controller owned by this adapter.
  @override
  void dispose() {
    _controller.dispose();
  }
}
