import 'package:flutter/material.dart';

/// Semantic icon roles used by reusable components instead of raw icon choices.
enum AppIcon {
  add,
  back,
  check,
  close,
  compress,
  delete,
  download,
  error,
  file,
  folder,
  image,
  info,
  more,
  pause,
  play,
  refresh,
  save,
  search,
  settings,
  share,
  success,
  tune,
  upload,
  warning,
}

/// Central Material icon resolver.
abstract final class AppIcons {
  static const Map<AppIcon, IconData> _filled = <AppIcon, IconData>{
    AppIcon.add: Icons.add,
    AppIcon.back: Icons.arrow_back,
    AppIcon.check: Icons.check,
    AppIcon.close: Icons.close,
    AppIcon.compress: Icons.compress,
    AppIcon.delete: Icons.delete,
    AppIcon.download: Icons.download,
    AppIcon.error: Icons.error,
    AppIcon.file: Icons.insert_drive_file,
    AppIcon.folder: Icons.folder,
    AppIcon.image: Icons.image,
    AppIcon.info: Icons.info,
    AppIcon.more: Icons.more_horiz,
    AppIcon.pause: Icons.pause,
    AppIcon.play: Icons.play_arrow,
    AppIcon.refresh: Icons.refresh,
    AppIcon.save: Icons.save,
    AppIcon.search: Icons.search,
    AppIcon.settings: Icons.settings,
    AppIcon.share: Icons.share,
    AppIcon.success: Icons.check_circle,
    AppIcon.tune: Icons.tune,
    AppIcon.upload: Icons.file_upload,
    AppIcon.warning: Icons.warning,
  };

  static const Map<AppIcon, IconData> _outlined = <AppIcon, IconData>{
    AppIcon.add: Icons.add,
    AppIcon.back: Icons.arrow_back,
    AppIcon.check: Icons.check,
    AppIcon.close: Icons.close,
    AppIcon.compress: Icons.compress,
    AppIcon.delete: Icons.delete_outline,
    AppIcon.download: Icons.download_outlined,
    AppIcon.error: Icons.error_outline,
    AppIcon.file: Icons.insert_drive_file_outlined,
    AppIcon.folder: Icons.folder_outlined,
    AppIcon.image: Icons.image_outlined,
    AppIcon.info: Icons.info_outline,
    AppIcon.more: Icons.more_horiz,
    AppIcon.pause: Icons.pause,
    AppIcon.play: Icons.play_arrow,
    AppIcon.refresh: Icons.refresh,
    AppIcon.save: Icons.save_outlined,
    AppIcon.search: Icons.search,
    AppIcon.settings: Icons.settings_outlined,
    AppIcon.share: Icons.share_outlined,
    AppIcon.success: Icons.check_circle_outline,
    AppIcon.tune: Icons.tune,
    AppIcon.upload: Icons.file_upload_outlined,
    AppIcon.warning: Icons.warning_amber,
  };

  static const Map<AppIcon, IconData> _rounded = <AppIcon, IconData>{
    AppIcon.add: Icons.add_rounded,
    AppIcon.back: Icons.arrow_back_rounded,
    AppIcon.check: Icons.check_rounded,
    AppIcon.close: Icons.close_rounded,
    AppIcon.compress: Icons.compress_rounded,
    AppIcon.delete: Icons.delete_outline_rounded,
    AppIcon.download: Icons.download_rounded,
    AppIcon.error: Icons.error_outline_rounded,
    AppIcon.file: Icons.insert_drive_file_rounded,
    AppIcon.folder: Icons.folder_rounded,
    AppIcon.image: Icons.image_rounded,
    AppIcon.info: Icons.info_outline_rounded,
    AppIcon.more: Icons.more_horiz_rounded,
    AppIcon.pause: Icons.pause_rounded,
    AppIcon.play: Icons.play_arrow_rounded,
    AppIcon.refresh: Icons.refresh_rounded,
    AppIcon.save: Icons.save_rounded,
    AppIcon.search: Icons.search_rounded,
    AppIcon.settings: Icons.settings_rounded,
    AppIcon.share: Icons.share_rounded,
    AppIcon.success: Icons.check_circle_rounded,
    AppIcon.tune: Icons.tune_rounded,
    AppIcon.upload: Icons.file_upload_rounded,
    AppIcon.warning: Icons.warning_amber_rounded,
  };

  static IconData resolve(
    AppIcon icon, {
    AppIconStyle style = AppIconStyle.rounded,
  }) => switch (style) {
    AppIconStyle.filled => _filled[icon]!,
    AppIconStyle.outlined => _outlined[icon]!,
    AppIconStyle.rounded => _rounded[icon]!,
  };

  static Icon icon(
    AppIcon icon, {
    AppIconStyle style = AppIconStyle.rounded,
    double? size,
    Color? color,
  }) => Icon(
    resolve(icon, style: style),
    size: size,
    color: color,
  );
}

enum AppIconStyle { filled, outlined, rounded }
