// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Comprezza – Photo Compressor & Converter';

  @override
  String get appName => 'Comprezza';

  @override
  String get appTagline => 'Compress. Convert. Optimize.';

  @override
  String get home => 'Home';

  @override
  String get compress => 'Compress';

  @override
  String get history => 'History';

  @override
  String get insights => 'Insights';

  @override
  String get settings => 'Settings';

  @override
  String get benchmark => 'Benchmark';

  @override
  String get about => 'About Comprezza';

  @override
  String get moreDestinations => 'More destinations';

  @override
  String get openSettings => 'Open settings';

  @override
  String get switchToLightMode => 'Switch to light mode';

  @override
  String get switchToDarkMode => 'Switch to dark mode';

  @override
  String get selectImages => 'Select images';

  @override
  String get selectImagesTooltip => 'Select images to compress';

  @override
  String get choosePhotos => 'Choose photos';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get quickActionsSubtitle => 'Everything you need, one tap away.';

  @override
  String get compressionPresets => 'Compression presets';

  @override
  String get compressionPresetsSubtitle =>
      'Start with a setting that fits the moment.';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get recentActivitySubtitle =>
      'Your work stays private on this device.';

  @override
  String get viewHistory => 'View history';

  @override
  String get yourImpact => 'Your impact';

  @override
  String get yourImpactSubtitle => 'A little space saved adds up.';

  @override
  String get seeAll => 'See all';

  @override
  String get heroWelcome => 'Compress photos privately on your device.';

  @override
  String get privateLocalWorkflow =>
      'Comprezza keeps your photo workflow private and local';

  @override
  String get storageSavings => 'Storage savings';

  @override
  String get storageSavingsDescription =>
      'Your optimized files stay on this device.';

  @override
  String get storageSavingsProgress =>
      'Storage savings progress. No savings recorded yet.';

  @override
  String get savedSoFar => 'saved so far';

  @override
  String get recentFilesEmptyTitle => 'No recent compressions yet';

  @override
  String get recentFilesEmptyMessage =>
      'Choose photos to get started — your latest results will appear here.';

  @override
  String get learnHowItWorks => 'Learn how it works';

  @override
  String get imagesCompressed => 'Images compressed';

  @override
  String get storageSaved => 'Storage saved';

  @override
  String get todaysSavings => 'Today’s savings';

  @override
  String get averageCompression => 'Average compression';

  @override
  String get spaceSaved => 'Space saved';

  @override
  String get averageReduction => 'Average reduction';

  @override
  String get smartTip => 'SMART TIP';

  @override
  String get nextTip => 'Next tip';

  @override
  String get compressPhotos => 'Compress photos';

  @override
  String get compressPhotosSubtitle => 'Free up space fast';

  @override
  String get batchCompress => 'Batch compress';

  @override
  String get batchCompressSubtitle => 'Many photos at once';

  @override
  String get batchCompressMany => 'Batch compress multiple photos';

  @override
  String get batchTitle => 'Compress a batch';

  @override
  String get batchSubtitle =>
      'Optimize dozens of photos in one clear, controlled queue.';

  @override
  String get batchEmptyTitle => 'Start with a group of photos';

  @override
  String get batchEmptySubtitle =>
      'Select multiple images, review the estimates, then run one efficient queue.';

  @override
  String get batchSelectImages => 'Select multiple images';

  @override
  String get batchPrivateNote =>
      'Photos are processed privately on this device.';

  @override
  String get batchAddImages => 'Add more images';

  @override
  String get batchSelect => 'Select';

  @override
  String get batchSelectAll => 'Select all';

  @override
  String get batchDeselectAll => 'Deselect all';

  @override
  String get batchRemoveImage => 'Remove image';

  @override
  String get batchImages => 'Images';

  @override
  String get batchOriginalSize => 'Original size';

  @override
  String get batchEstimatedOutput => 'Estimated output';

  @override
  String get batchEstimatedSavings => 'Estimated savings';

  @override
  String get batchSelectStep => 'Select';

  @override
  String get batchAnalyzeStep => 'Analyze';

  @override
  String get batchPreviewStep => 'Preview';

  @override
  String get batchProcessStep => 'Compress';

  @override
  String get batchCompleteStep => 'Complete';

  @override
  String workflowStepPosition(int current, int total, String label) {
    return 'Step $current of $total: $label';
  }

  @override
  String get batchAnalyzing => 'Analyzing batch';

  @override
  String get batchPreview => 'Batch preview';

  @override
  String get batchPreviewSubtitle =>
      'Review each image before creating the queue.';

  @override
  String get batchQueue => 'Compression queue';

  @override
  String get batchQueueSubtitle =>
      'One bounded worker keeps memory use predictable.';

  @override
  String get batchSettings => 'Apply settings';

  @override
  String get batchPreset => 'Preset';

  @override
  String get batchStartCompression => 'Start compression';

  @override
  String get batchCompressing => 'Compressing';

  @override
  String get batchProgress => 'Batch progress';

  @override
  String get batchCompleted => 'completed';

  @override
  String get batchRemaining => 'remaining';

  @override
  String get batchPaused => 'Finishing current image before pausing';

  @override
  String get batchPause => 'Pause queue';

  @override
  String get batchResume => 'Resume queue';

  @override
  String get batchCancel => 'Cancel queue';

  @override
  String get batchRetryFailed => 'Retry failed';

  @override
  String get batchWaiting => 'Waiting';

  @override
  String get batchFailed => 'Failed';

  @override
  String get batchCancelled => 'Cancelled';

  @override
  String get batchSkipped => 'Skipped';

  @override
  String get batchSummary => 'Batch complete';

  @override
  String get batchProcessed => 'Processed';

  @override
  String get batchCompressedSize => 'Compressed size';

  @override
  String get batchStorageSaved => 'Storage saved';

  @override
  String get batchCompressionRatio => 'Compression ratio';

  @override
  String get batchSaveAll => 'Save all';

  @override
  String get batchShareSelected => 'Share selected';

  @override
  String get batchPrepareZip => 'Prepare ZIP';

  @override
  String batchSavedToDevice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saved $count images to Pictures / Comprezza',
      one: 'Saved 1 image to Pictures / Comprezza',
    );
    return '$_temp0';
  }

  @override
  String get batchSaveFailed =>
      'Comprezza could not save the images. Please try again.';

  @override
  String get batchShareFailed =>
      'Comprezza could not open sharing. Please try again.';

  @override
  String get batchZipTitle => 'ZIP ready';

  @override
  String batchZipFiles(int count, String size) {
    return '$count files · $size';
  }

  @override
  String get batchZipSave => 'Save ZIP';

  @override
  String get batchZipShare => 'Share ZIP';

  @override
  String get batchZipSaved => 'ZIP saved to Downloads';

  @override
  String get batchZipFailed =>
      'Comprezza could not build the ZIP. Please try again.';

  @override
  String get batchStartOver => 'Start over';

  @override
  String get historyTitle => 'Your compression history';

  @override
  String get historySearch => 'Search history';

  @override
  String get historySearchHint => 'Filename, preset, or output';

  @override
  String get historyDate => 'Date';

  @override
  String get historyFormat => 'Format';

  @override
  String get historyRatio => 'Ratio';

  @override
  String get historyPreset => 'Preset';

  @override
  String get historySort => 'Sort';

  @override
  String get historyNewest => 'Newest';

  @override
  String get historyOldest => 'Oldest';

  @override
  String get historyLargestFile => 'Largest file';

  @override
  String get historyAz => 'A–Z';

  @override
  String get historyZa => 'Z–A';

  @override
  String get historyClearFilters => 'Clear filters';

  @override
  String get historyFavorites => 'Pinned results';

  @override
  String get historyResults => 'Matching sessions';

  @override
  String get historyAllSessions => 'All sessions';

  @override
  String get historySaved => 'Saved';

  @override
  String get historySavedSemantic => 'saved';

  @override
  String get historyPin => 'Pin result';

  @override
  String get historyUnpin => 'Unpin result';

  @override
  String get historyExport => 'Export history';

  @override
  String get historyExportCsv => 'Export CSV';

  @override
  String get historyExportJson => 'Export JSON';

  @override
  String get historyExportPdf => 'Export PDF';

  @override
  String get historyExportReady =>
      'History export is ready for the approved integration.';

  @override
  String get historyPdfReserved =>
      'PDF generation is reserved for a future export phase.';

  @override
  String get historyDeleteTitle => 'Delete history entry?';

  @override
  String get historyDeleteMessage =>
      'This removes the local history record. The generated image is not deleted here.';

  @override
  String get historyDeleted => 'History entry deleted';

  @override
  String get historyEmptyTitle => 'Your compression story starts here';

  @override
  String get historyEmptyMessage =>
      'Compress a photo to begin building a private record of your storage savings.';

  @override
  String get historyNoResultsTitle => 'No matching sessions';

  @override
  String get historyNoResultsMessage =>
      'Try a different filename or clear the active filters.';

  @override
  String get historyRatioUnderTwo => 'Under 2×';

  @override
  String get historyRatioTwoToFour => '2× to 4×';

  @override
  String get historyRatioOverFour => 'Over 4×';

  @override
  String get historyBeforeImage => 'Before image';

  @override
  String get historyAfterImage => 'After image';

  @override
  String get historyMetadataStatus => 'Metadata status';

  @override
  String get insightsTitle => 'Your storage impact';

  @override
  String get insightsSubtitle =>
      'A private view of the space Comprezza has helped you reclaim.';

  @override
  String get historyThisWeek => 'This week';

  @override
  String get historyLifetimeSaved => 'Lifetime saved';

  @override
  String get historyStorageSaved => 'Storage saved';

  @override
  String get historyBatchSessions => 'Batch sessions';

  @override
  String get historySavedOverTime => 'Storage saved over time';

  @override
  String get historySavedOverTimeSubtitle =>
      'The last seven local activity points';

  @override
  String get historyRatioTrend => 'Compression ratio trend';

  @override
  String get historyRatioTrendSubtitle => 'Recent completed sessions';

  @override
  String get historyLargestImage => 'Largest image compressed';

  @override
  String get historyLargestSaving => 'Largest storage saving';

  @override
  String get historyAverageTime => 'Average processing time';

  @override
  String get historyMostUsedPreset => 'Most used preset';

  @override
  String get historyMostUsedFormat => 'Most used format';

  @override
  String get historyImageType => 'Most common image type';

  @override
  String get sixDaysAgo => '6 days ago';

  @override
  String get historyMilestones => 'Milestones';

  @override
  String get achievementFirstTitle => 'First compression';

  @override
  String get achievementFirstDescription =>
      'Complete your first local compression.';

  @override
  String get achievementHundredTitle => '100 images compressed';

  @override
  String get achievementHundredDescription =>
      'Compress 100 images on this device.';

  @override
  String get achievementGbTitle => '1 GB saved';

  @override
  String get achievementGbDescription => 'Save one gigabyte of local storage.';

  @override
  String get all => 'All';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This week';

  @override
  String get thisMonth => 'This month';

  @override
  String get other => 'Other';

  @override
  String get notAvailable => 'Not available';

  @override
  String get clear => 'Clear';

  @override
  String get undo => 'Undo';

  @override
  String get delete => 'Delete';

  @override
  String get convertFormat => 'Convert format';

  @override
  String get convertFormatSubtitle => 'JPEG, PNG, WebP';

  @override
  String get resizeImage => 'Resize image';

  @override
  String get resizeImageSubtitle => 'Perfect dimensions';

  @override
  String get benchmarkSubtitle => 'Compare settings';

  @override
  String get historySubtitle => 'See your activity';

  @override
  String get settingsSubtitle => 'Make it yours';

  @override
  String get webReady => 'Web ready';

  @override
  String get webReadySubtitle => 'Small files, crisp detail';

  @override
  String get socialShare => 'Social share';

  @override
  String get socialShareSubtitle => 'Balanced quality and size';

  @override
  String get lossless => 'Lossless';

  @override
  String get losslessSubtitle => 'Preserve every detail';

  @override
  String get tipWebTitle => 'A lighter web, one image at a time';

  @override
  String get tipWebMessage =>
      'Use WebP for websites when you want excellent quality in a smaller file.';

  @override
  String get tipScreenshotTitle => 'Keep screenshots crisp';

  @override
  String get tipScreenshotMessage =>
      'Compress screenshots losslessly to preserve text and sharp edges.';

  @override
  String get tipBatchTitle => 'Save time in batches';

  @override
  String get tipBatchMessage =>
      'When you have a full album, batch compression keeps the workflow moving.';

  @override
  String get tipMetadataTitle => 'Metadata, your choice';

  @override
  String get tipMetadataMessage =>
      'Keep metadata only when you need capture details to travel with the image.';

  @override
  String get historyPlaceholderMessage =>
      'Your local compression history will appear here.';

  @override
  String get settingsPlaceholderMessage =>
      'Personalization and preferences will live here.';

  @override
  String get benchmarkPlaceholderMessage =>
      'Compare processing options when Benchmark Mode arrives.';

  @override
  String get aboutPlaceholderMessage =>
      'Private, local, and designed to keep your moments yours.';

  @override
  String get workflowTitle => 'Compress your image';

  @override
  String get workflowSubtitle => 'A clear path from original to optimized.';

  @override
  String get workflowPresetBalanced => 'Balanced';

  @override
  String get workflowPresetBalancedSubtitle => 'The everyday default';

  @override
  String get workflowPresetMaximumQuality => 'Maximum quality';

  @override
  String get workflowPresetMaximumQualitySubtitle => 'Best possible fidelity';

  @override
  String get workflowPresetSmallestSize => 'Smallest size';

  @override
  String get workflowPresetSmallestSizeSubtitle => 'Tiny files, still clear';

  @override
  String get workflowPresetBadge => 'PRESET';

  @override
  String get advancedOptions => 'Advanced options';

  @override
  String get advancedOptionsDescription =>
      'Fine-tune format, dimensions, and metadata.';

  @override
  String successQualityFormat(int quality, String format) {
    return 'Quality used $quality% · Format $format';
  }

  @override
  String get batchPresetBalanced => 'Balanced';

  @override
  String get batchPresetBalancedSubtitle => 'Everyday default';

  @override
  String get batchPresetWebReady => 'Web ready';

  @override
  String get batchPresetWebReadySubtitle => 'Small files, crisp detail';

  @override
  String get batchPresetSmallest => 'Smallest';

  @override
  String get batchPresetSmallestSubtitle => 'Tiny files, still clear';

  @override
  String get supportedFormats => 'JPEG · PNG · WebP · HEIC';

  @override
  String get selectFromGallery => 'Choose from gallery';

  @override
  String get useCamera => 'Use camera';

  @override
  String get imageAnalysis => 'Image analysis';

  @override
  String get recommended => 'Recommended';

  @override
  String get confidence => 'confidence';

  @override
  String get confidenceValue => '92%';

  @override
  String get compressionOptions => 'Compression options';

  @override
  String get quality => 'Quality';

  @override
  String get qualityDescription => 'Balance visual quality and file size.';

  @override
  String get targetFileSize => 'Target file size';

  @override
  String get target100Kb => '100 KB';

  @override
  String get target250Kb => '250 KB';

  @override
  String get target500Kb => '500 KB';

  @override
  String get target1Mb => '1 MB';

  @override
  String get target2Mb => '2 MB';

  @override
  String get target5Mb => '5 MB';

  @override
  String get outputFormat => 'Output format';

  @override
  String get jpegFormat => 'JPEG';

  @override
  String get pngFormat => 'PNG';

  @override
  String get webpFormat => 'WebP';

  @override
  String get formatDescription =>
      'Choose the format that fits where you will use it.';

  @override
  String get resize => 'Resize';

  @override
  String get resizeDescription =>
      'Keep the original dimensions or scale the image down.';

  @override
  String get originalDimensions => 'Original dimensions';

  @override
  String get metadata => 'Metadata';

  @override
  String get keepMetadata => 'Keep metadata';

  @override
  String get removeMetadata => 'Remove metadata';

  @override
  String get metadataDescription =>
      'Removing metadata can save space and protect capture details.';

  @override
  String get liveEstimate => 'Live estimate';

  @override
  String get estimatedSize => 'Estimated output';

  @override
  String get estimatedSavings => 'Estimated savings';

  @override
  String get compressionRatio => 'Compression ratio';

  @override
  String get preview => 'Preview';

  @override
  String get original => 'Original';

  @override
  String get compressed => 'Compressed';

  @override
  String get analysisReady => 'Analysis complete';

  @override
  String get compressNow => 'Compress now';

  @override
  String get compressing => 'Compressing your image';

  @override
  String get processingImage => 'Processing image';

  @override
  String get success => 'Compression complete';

  @override
  String get successMessage =>
      'Your optimized image is ready to save or share.';

  @override
  String get saveToDevice => 'Save to device';

  @override
  String get savedToPictures => 'Saved to Pictures / Comprezza';

  @override
  String get openingShareSheet => 'Opening your share sheet…';

  @override
  String get share => 'Share';

  @override
  String get compressAgain => 'Compress again';

  @override
  String get startOver => 'Start over';

  @override
  String get tryAgain => 'Try again';

  @override
  String get privateProcessing => 'Processed privately on your device';

  @override
  String get originalSize => 'Original size';

  @override
  String get outputSize => 'Output size';

  @override
  String get qualityUsed => 'Quality used';

  @override
  String get formatUsed => 'Format';

  @override
  String get processingTime => 'Processing time';

  @override
  String get originalOption => 'Original';

  @override
  String get resize75 => '75%';

  @override
  String get resize50 => '50%';

  @override
  String get resize25 => '25%';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get settingsExport => 'Export settings';

  @override
  String get settingsExportReady =>
      'A privacy-safe settings export is ready in app storage.';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsGeneralSubtitle =>
      'Make Comprezza behave the way you prefer.';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsResizeMode => 'Default resize mode';

  @override
  String get settingsAutoAnalyze => 'Auto-analyze images';

  @override
  String get settingsAutoRecommend => 'Recommend compression';

  @override
  String get settingsRememberLast => 'Remember last used settings';

  @override
  String get settingsOpenLastScreen => 'Open last screen';

  @override
  String get settingsCompression => 'Compression';

  @override
  String get settingsCompressionSubtitle =>
      'Set the quality, format, and intelligence behind each workflow.';

  @override
  String get settingsAlgorithm => 'Preferred algorithm';

  @override
  String get settingsOutputFormat => 'Default output format';

  @override
  String get settingsKeepMetadata => 'Always keep metadata';

  @override
  String get settingsSmartRecommendations => 'Smart recommendations';

  @override
  String get settingsLiveEstimate => 'Live size estimation';

  @override
  String get settingsBenchmark => 'Compression benchmark';

  @override
  String get settingsTargetByDefault => 'Compress to target size by default';

  @override
  String get settingsQuality => 'Compression quality';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get settingsStorageSubtitle =>
      'Keep generated files tidy and predictable.';

  @override
  String get settingsAutoDeleteTemporary => 'Auto-delete temporary files';

  @override
  String get settingsCleanupInterval => 'Cleanup interval';

  @override
  String get settingsMaximumCache => 'Maximum cache size';

  @override
  String get settingsClearCache => 'Clear cache';

  @override
  String get settingsClearCacheMessage =>
      'Only generated app cache will be removed. Original photos are never touched.';

  @override
  String get settingsClearHistory => 'Clear history';

  @override
  String get settingsClearHistoryMessage =>
      'Remove local compression history metadata? Generated exports are not deleted.';

  @override
  String get settingsResetStorage => 'Reset storage';

  @override
  String get settingsResetStorageMessage =>
      'Clear generated cache and local history metadata from this device.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAppearanceSubtitle =>
      'Tune the visual rhythm for your device and your eyes.';

  @override
  String get settingsDynamicColors => 'Material You dynamic colors';

  @override
  String get settingsAdaptiveIcons => 'Adaptive icons';

  @override
  String get settingsLargeUi => 'Large UI mode';

  @override
  String get settingsCompactUi => 'Compact UI mode';

  @override
  String get settingsAnimationSpeed => 'Animation speed';

  @override
  String get settingsFontScaling => 'Font scaling';

  @override
  String get settingsAccessibility => 'Accessibility';

  @override
  String get settingsAccessibilitySubtitle =>
      'Comfortable controls, clear feedback, and strong semantics.';

  @override
  String get settingsScreenReaders => 'Screen reader support';

  @override
  String get settingsHighContrast => 'High contrast';

  @override
  String get settingsLargeTouchTargets => 'Large touch targets';

  @override
  String get settingsDynamicText => 'Dynamic text scaling';

  @override
  String get settingsReduceAnimations => 'Reduce animations';

  @override
  String get settingsColorBlindPalette => 'Color-blind friendly palette';

  @override
  String get settingsProgressAnnouncements => 'Progress announcements';

  @override
  String get settingsSemanticLabels => 'Semantic labels';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsPrivacySubtitle =>
      'Your privacy baseline is always visible and always local.';

  @override
  String get settingsOfflineProcessing => 'Offline processing';

  @override
  String get settingsNoCloudUpload => 'No cloud uploads';

  @override
  String get settingsNoAnalytics => 'No analytics';

  @override
  String get settingsNoTracking => 'No tracking';

  @override
  String get settingsPrivacyAlwaysOn => 'Always on in Comprezza';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsOpenSource => 'Open-source libraries';

  @override
  String get settingsAdvanced => 'Advanced';

  @override
  String get settingsAdvancedSubtitle =>
      'Import, export, diagnostics, and carefully gated controls.';

  @override
  String get settingsBenchmarkMode => 'Benchmark mode';

  @override
  String get settingsDeveloperLogging => 'Developer logging';

  @override
  String get settingsVerboseLogging => 'Verbose logging (debug only)';

  @override
  String get settingsExportConfiguration => 'Export configuration';

  @override
  String get settingsImportConfiguration => 'Import configuration';

  @override
  String get settingsImportDescription =>
      'Choose a Comprezza settings export from app-private storage. Sensitive paths and debug data are excluded.';

  @override
  String get settingsFactoryReset => 'Factory reset';

  @override
  String get settingsFactoryResetMessage =>
      'Reset preferences and remove generated cache and local history metadata? This cannot be undone.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutSubtitle => 'Comprezza, by Dzynova Technologies.';

  @override
  String get settingsWebsite => 'Website';

  @override
  String get settingsDeveloper => 'Dzynova Technologies';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsBuildNumber => 'Build number';

  @override
  String get settingsRateApp => 'Rate Comprezza';

  @override
  String get settingsShareApp => 'Share Comprezza';

  @override
  String get settingsChangelog => 'Changelog';

  @override
  String get settingsDeveloperOptions => 'Developer options';

  @override
  String get settingsDeveloperOptionsSubtitle =>
      'Unlocked locally in debug builds. Never shown in release mode.';

  @override
  String get settingsViewEngineStatus => 'View engine status';

  @override
  String get settingsViewQueueStatus => 'View queue status';

  @override
  String get settingsViewCacheStatus => 'View cache status';

  @override
  String get settingsPerformanceMonitor => 'Performance monitor';

  @override
  String get settingsFrameStatistics => 'Frame rendering statistics';

  @override
  String get settingsMemoryStatistics => 'Memory statistics';

  @override
  String get settingsDependencyGraph => 'Dependency graph';

  @override
  String get settingsCompressionBenchmark => 'Compression benchmark';

  @override
  String get settingsExperimentalFeatures => 'Experimental features';

  @override
  String get settingsFeatureFlags => 'Feature flags';

  @override
  String get settingsStatusReady => 'Ready';

  @override
  String get settingsStatusIdle => 'Idle';

  @override
  String get settingsStatusProtected => 'Protected';

  @override
  String get settingsStatusLocalOnly => 'Local only';

  @override
  String get settingsStatusDebugOnly => 'Debug only';

  @override
  String get settingsResetAppearance => 'Reset appearance';

  @override
  String get settingsResetCompression => 'Reset compression';

  @override
  String get settingsResetRecommendations => 'Reset recommendations';

  @override
  String get settingsResetAppearanceMessage =>
      'Restore the default appearance preferences?';

  @override
  String get settingsResetCompressionMessage =>
      'Restore the default compression preferences?';

  @override
  String get settingsResetRecommendationsMessage =>
      'Restore the default recommendation preferences?';

  @override
  String get settingsReset => 'Reset';

  @override
  String get settingsConfirm => 'Confirm';

  @override
  String get settingsSystemTheme => 'System';

  @override
  String get settingsLightTheme => 'Light';

  @override
  String get settingsDarkTheme => 'Dark';

  @override
  String get settingsOriginalResize => 'Original dimensions';

  @override
  String get settingsAutomatic => 'Automatic';

  @override
  String get settingsNever => 'Never';

  @override
  String get settingsDaily => 'Daily';

  @override
  String get settingsWeekly => 'Weekly';

  @override
  String get settingsMonthly => 'Monthly';

  @override
  String get settingsFullMotion => 'Full';

  @override
  String get settingsReducedMotion => 'Reduced';

  @override
  String get settingsMotionOff => 'Off';

  @override
  String get settingsHeroSemantic => 'Settings personalization overview';

  @override
  String get settingsHeroTitle => 'Comprezza';

  @override
  String get settingsHeroSubtitle => 'Private photo compression.';

  @override
  String get settingsRecommendations => 'Recommended for you';

  @override
  String get settingsRecommendationLargeCache => 'Large cache detected';

  @override
  String get settingsRecommendationLargeCacheMessage =>
      'Consider clearing generated cache to reclaim local storage.';

  @override
  String get settingsRecommendationScreenshots => 'Screenshots are frequent';

  @override
  String get settingsRecommendationScreenshotsMessage =>
      'A PNG preset can keep text and sharp edges crisp.';

  @override
  String get settingsRecommendationPhotos => 'Photos are frequent';

  @override
  String get settingsRecommendationPhotosMessage =>
      'A JPEG preset is a balanced default for photos.';

  @override
  String get settingsRecommendationWebsite => 'Website images are frequent';

  @override
  String get settingsRecommendationWebsiteMessage =>
      'WebP can reduce file size while preserving web-ready quality.';

  @override
  String get settingsRecommendationLowStorage => 'Storage is running low';

  @override
  String get settingsRecommendationLowStorageMessage =>
      'Enable automatic cleanup and keep temporary files short-lived.';

  @override
  String get settingsRecommendationGeneric =>
      'A local optimization is available';

  @override
  String get settingsRecommendationGenericMessage =>
      'Review your settings to keep this device tidy.';

  @override
  String settingsPercentValue(int value) {
    return '$value%';
  }

  @override
  String settingsMegabytesValue(int value) {
    return '$value MB';
  }

  @override
  String get settingsPrivacyPolicyDescription =>
      'Comprezza processes selected images locally and does not intentionally upload them. The published policy must be reviewed before release.';

  @override
  String get settingsOpenSourceDescription =>
      'This screen uses Flutter and the packages listed in the project license notices.';

  @override
  String get settingsChangelogDescription =>
      'Review the project changelog for transparent release and architecture notes.';

  @override
  String get settingsLoadFailed =>
      'Settings could not be loaded. Defaults are being used.';

  @override
  String get settingsSaveFailed =>
      'Settings could not be saved. Your last saved values were restored.';

  @override
  String get settingsExportFailed => 'Settings export could not be created.';

  @override
  String get settingsImportFailed =>
      'That settings export could not be imported.';

  @override
  String get settingsStorageActionFailed =>
      'The storage action could not be completed.';

  @override
  String get settingsRemoveMetadata => 'Always remove metadata';

  @override
  String get settingsQualityPreview => 'Compression quality preview';

  @override
  String get settingsHistorySizeLimit => 'Compression history size limit';

  @override
  String get settingsErrorAnnouncements => 'Error announcements';

  @override
  String get settingsNoUserAccounts => 'No user accounts';

  @override
  String get settingsTerms => 'Terms of use';

  @override
  String get settingsLicenses => 'Licenses';

  @override
  String get settingsAcknowledgements => 'Acknowledgements';

  @override
  String settingsKilobytesValue(int value) {
    return '$value KB';
  }

  @override
  String settingsItemsValue(int value) {
    return '$value items';
  }

  @override
  String get settingsTermsDescription =>
      'Review the terms that govern use of Comprezza.';

  @override
  String get settingsLicensesDescription =>
      'Review the open-source license notices included with Comprezza.';

  @override
  String get settingsAcknowledgementsDescription =>
      'Comprezza is built with the Flutter ecosystem and its open-source contributors.';

  @override
  String get settingsDefaultPreset => 'Default compression preset';

  @override
  String get settingsBalancedPreset => 'Balanced';

  @override
  String get settingsWebPreset => 'Web';

  @override
  String get settingsLosslessPreset => 'Lossless';

  @override
  String get settingsDefaultTarget => 'Default target file size';

  @override
  String get settingsNoTarget => 'No target';

  @override
  String get settingsAutoDeleteOldHistory => 'Auto-delete old history';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsSubtitle =>
      'Notification controls are ready for a future local integration.';

  @override
  String get settingsNotificationsFutureReady =>
      'Future-ready notification controls';

  @override
  String get settingsNotificationsFutureReadyMessage =>
      'No notifications are enabled yet.';

  @override
  String get settingsStorageOverview => 'Storage usage overview';

  @override
  String settingsStorageOverviewValue(String value) {
    return 'Using $value across Comprezza storage';
  }

  @override
  String get settingsDisplayDensity => 'Display density';

  @override
  String get settingsComfortableDensity => 'Comfortable';

  @override
  String get settingsCompactDensity => 'Compact';

  @override
  String get settingsStorageCache => 'Cache';

  @override
  String get settingsStorageTemporary => 'Temporary files';

  @override
  String get settingsStorageHistory => 'History';

  @override
  String get settingsStorageExports => 'Exports';

  @override
  String get benchmarkChooseImage => 'Choose an image';

  @override
  String get benchmarkRun => 'Run benchmark';

  @override
  String get benchmarkRunning => 'Benchmarking compression…';

  @override
  String get benchmarkEmptyTitle => 'No benchmark yet';

  @override
  String get benchmarkEmptyMessage =>
      'Pick a photo and Comprezza will compare how each quality setting changes time and size — privately, on this device.';

  @override
  String get benchmarkResults => 'Results';

  @override
  String get benchmarkComparison => 'Quality comparison';

  @override
  String get benchmarkFastest => 'Fastest run';

  @override
  String get benchmarkBestRatio => 'Best ratio';

  @override
  String get benchmarkTotalSaved => 'Total saved';

  @override
  String get benchmarkSpeed => 'Speed';

  @override
  String get benchmarkTime => 'Time';

  @override
  String get aboutLegal => 'Legal';

  @override
  String get historyLoadFailed =>
      'Your compression history could not be loaded.';

  @override
  String get historyShareReserved =>
      'Sharing generated files is reserved for a future integration.';
}
