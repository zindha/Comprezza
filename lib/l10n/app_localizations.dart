import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Comprezza – Photo Compressor & Converter'**
  String get appTitle;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Comprezza'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Compress. Convert. Optimize.'**
  String get appTagline;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @compress.
  ///
  /// In en, this message translates to:
  /// **'Compress'**
  String get compress;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @benchmark.
  ///
  /// In en, this message translates to:
  /// **'Benchmark'**
  String get benchmark;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About Comprezza'**
  String get about;

  /// No description provided for @moreDestinations.
  ///
  /// In en, this message translates to:
  /// **'More destinations'**
  String get moreDestinations;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @switchToLightMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get switchToLightMode;

  /// No description provided for @switchToDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get switchToDarkMode;

  /// No description provided for @selectImages.
  ///
  /// In en, this message translates to:
  /// **'Select images'**
  String get selectImages;

  /// No description provided for @selectImagesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select images to compress'**
  String get selectImagesTooltip;

  /// No description provided for @choosePhotos.
  ///
  /// In en, this message translates to:
  /// **'Choose photos'**
  String get choosePhotos;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @quickActionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything you need, one tap away.'**
  String get quickActionsSubtitle;

  /// No description provided for @compressionPresets.
  ///
  /// In en, this message translates to:
  /// **'Compression presets'**
  String get compressionPresets;

  /// No description provided for @compressionPresetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start with a setting that fits the moment.'**
  String get compressionPresetsSubtitle;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @recentActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your work stays private on this device.'**
  String get recentActivitySubtitle;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View history'**
  String get viewHistory;

  /// No description provided for @yourImpact.
  ///
  /// In en, this message translates to:
  /// **'Your impact'**
  String get yourImpact;

  /// No description provided for @yourImpactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A little space saved adds up.'**
  String get yourImpactSubtitle;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @heroWelcome.
  ///
  /// In en, this message translates to:
  /// **'Compress photos privately on your device.'**
  String get heroWelcome;

  /// No description provided for @privateLocalWorkflow.
  ///
  /// In en, this message translates to:
  /// **'Comprezza keeps your photo workflow private and local'**
  String get privateLocalWorkflow;

  /// No description provided for @storageSavings.
  ///
  /// In en, this message translates to:
  /// **'Storage savings'**
  String get storageSavings;

  /// No description provided for @storageSavingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Your optimized files stay on this device.'**
  String get storageSavingsDescription;

  /// No description provided for @storageSavingsProgress.
  ///
  /// In en, this message translates to:
  /// **'Storage savings progress. No savings recorded yet.'**
  String get storageSavingsProgress;

  /// No description provided for @savedSoFar.
  ///
  /// In en, this message translates to:
  /// **'saved so far'**
  String get savedSoFar;

  /// No description provided for @recentFilesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recent compressions yet'**
  String get recentFilesEmptyTitle;

  /// No description provided for @recentFilesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose photos to get started — your latest results will appear here.'**
  String get recentFilesEmptyMessage;

  /// No description provided for @learnHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'Learn how it works'**
  String get learnHowItWorks;

  /// No description provided for @imagesCompressed.
  ///
  /// In en, this message translates to:
  /// **'Images compressed'**
  String get imagesCompressed;

  /// No description provided for @storageSaved.
  ///
  /// In en, this message translates to:
  /// **'Storage saved'**
  String get storageSaved;

  /// No description provided for @todaysSavings.
  ///
  /// In en, this message translates to:
  /// **'Today’s savings'**
  String get todaysSavings;

  /// No description provided for @averageCompression.
  ///
  /// In en, this message translates to:
  /// **'Average compression'**
  String get averageCompression;

  /// No description provided for @spaceSaved.
  ///
  /// In en, this message translates to:
  /// **'Space saved'**
  String get spaceSaved;

  /// No description provided for @averageReduction.
  ///
  /// In en, this message translates to:
  /// **'Average reduction'**
  String get averageReduction;

  /// No description provided for @smartTip.
  ///
  /// In en, this message translates to:
  /// **'SMART TIP'**
  String get smartTip;

  /// No description provided for @nextTip.
  ///
  /// In en, this message translates to:
  /// **'Next tip'**
  String get nextTip;

  /// No description provided for @compressPhotos.
  ///
  /// In en, this message translates to:
  /// **'Compress photos'**
  String get compressPhotos;

  /// No description provided for @compressPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free up space fast'**
  String get compressPhotosSubtitle;

  /// No description provided for @batchCompress.
  ///
  /// In en, this message translates to:
  /// **'Batch compress'**
  String get batchCompress;

  /// No description provided for @batchCompressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Many photos at once'**
  String get batchCompressSubtitle;

  /// No description provided for @batchCompressMany.
  ///
  /// In en, this message translates to:
  /// **'Batch compress multiple photos'**
  String get batchCompressMany;

  /// No description provided for @batchTitle.
  ///
  /// In en, this message translates to:
  /// **'Compress a batch'**
  String get batchTitle;

  /// No description provided for @batchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optimize dozens of photos in one clear, controlled queue.'**
  String get batchSubtitle;

  /// No description provided for @batchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Start with a group of photos'**
  String get batchEmptyTitle;

  /// No description provided for @batchEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select multiple images, review the estimates, then run one efficient queue.'**
  String get batchEmptySubtitle;

  /// No description provided for @batchSelectImages.
  ///
  /// In en, this message translates to:
  /// **'Select multiple images'**
  String get batchSelectImages;

  /// No description provided for @batchPrivateNote.
  ///
  /// In en, this message translates to:
  /// **'Photos are processed privately on this device.'**
  String get batchPrivateNote;

  /// No description provided for @batchAddImages.
  ///
  /// In en, this message translates to:
  /// **'Add more images'**
  String get batchAddImages;

  /// No description provided for @batchSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get batchSelect;

  /// No description provided for @batchSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get batchSelectAll;

  /// No description provided for @batchDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get batchDeselectAll;

  /// No description provided for @batchRemoveImage.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get batchRemoveImage;

  /// No description provided for @batchImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get batchImages;

  /// No description provided for @batchOriginalSize.
  ///
  /// In en, this message translates to:
  /// **'Original size'**
  String get batchOriginalSize;

  /// No description provided for @batchEstimatedOutput.
  ///
  /// In en, this message translates to:
  /// **'Estimated output'**
  String get batchEstimatedOutput;

  /// No description provided for @batchEstimatedSavings.
  ///
  /// In en, this message translates to:
  /// **'Estimated savings'**
  String get batchEstimatedSavings;

  /// No description provided for @batchSelectStep.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get batchSelectStep;

  /// No description provided for @batchAnalyzeStep.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get batchAnalyzeStep;

  /// No description provided for @batchPreviewStep.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get batchPreviewStep;

  /// No description provided for @batchProcessStep.
  ///
  /// In en, this message translates to:
  /// **'Compress'**
  String get batchProcessStep;

  /// No description provided for @batchCompleteStep.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get batchCompleteStep;

  /// The current position and label in a workflow progress indicator.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}: {label}'**
  String workflowStepPosition(int current, int total, String label);

  /// No description provided for @batchAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing batch'**
  String get batchAnalyzing;

  /// No description provided for @batchPreview.
  ///
  /// In en, this message translates to:
  /// **'Batch preview'**
  String get batchPreview;

  /// No description provided for @batchPreviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review each image before creating the queue.'**
  String get batchPreviewSubtitle;

  /// No description provided for @batchQueue.
  ///
  /// In en, this message translates to:
  /// **'Compression queue'**
  String get batchQueue;

  /// No description provided for @batchQueueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One bounded worker keeps memory use predictable.'**
  String get batchQueueSubtitle;

  /// No description provided for @batchSettings.
  ///
  /// In en, this message translates to:
  /// **'Apply settings'**
  String get batchSettings;

  /// No description provided for @batchPreset.
  ///
  /// In en, this message translates to:
  /// **'Preset'**
  String get batchPreset;

  /// No description provided for @batchStartCompression.
  ///
  /// In en, this message translates to:
  /// **'Start compression'**
  String get batchStartCompression;

  /// No description provided for @batchCompressing.
  ///
  /// In en, this message translates to:
  /// **'Compressing'**
  String get batchCompressing;

  /// No description provided for @batchProgress.
  ///
  /// In en, this message translates to:
  /// **'Batch progress'**
  String get batchProgress;

  /// No description provided for @batchCompleted.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get batchCompleted;

  /// No description provided for @batchRemaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get batchRemaining;

  /// No description provided for @batchPaused.
  ///
  /// In en, this message translates to:
  /// **'Finishing current image before pausing'**
  String get batchPaused;

  /// No description provided for @batchPause.
  ///
  /// In en, this message translates to:
  /// **'Pause queue'**
  String get batchPause;

  /// No description provided for @batchResume.
  ///
  /// In en, this message translates to:
  /// **'Resume queue'**
  String get batchResume;

  /// No description provided for @batchCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel queue'**
  String get batchCancel;

  /// No description provided for @batchRetryAll.
  ///
  /// In en, this message translates to:
  /// **'Retry all'**
  String get batchRetryAll;

  /// No description provided for @batchRetryFailed.
  ///
  /// In en, this message translates to:
  /// **'Retry failed'**
  String get batchRetryFailed;

  /// No description provided for @batchWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get batchWaiting;

  /// No description provided for @batchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get batchFailed;

  /// No description provided for @batchCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get batchCancelled;

  /// No description provided for @batchSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get batchSkipped;

  /// No description provided for @batchSummary.
  ///
  /// In en, this message translates to:
  /// **'Batch complete'**
  String get batchSummary;

  /// No description provided for @batchProcessed.
  ///
  /// In en, this message translates to:
  /// **'Processed'**
  String get batchProcessed;

  /// No description provided for @batchCompressedSize.
  ///
  /// In en, this message translates to:
  /// **'Compressed size'**
  String get batchCompressedSize;

  /// No description provided for @batchStorageSaved.
  ///
  /// In en, this message translates to:
  /// **'Storage saved'**
  String get batchStorageSaved;

  /// No description provided for @batchCompressionRatio.
  ///
  /// In en, this message translates to:
  /// **'Compression ratio'**
  String get batchCompressionRatio;

  /// No description provided for @batchSaveAll.
  ///
  /// In en, this message translates to:
  /// **'Save all'**
  String get batchSaveAll;

  /// No description provided for @batchShareSelected.
  ///
  /// In en, this message translates to:
  /// **'Share selected'**
  String get batchShareSelected;

  /// No description provided for @batchPrepareZip.
  ///
  /// In en, this message translates to:
  /// **'Prepare ZIP'**
  String get batchPrepareZip;

  /// Confirmation that batch outputs were saved to the device gallery.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Saved 1 image to Pictures / Comprezza} other{Saved {count} images to Pictures / Comprezza}}'**
  String batchSavedToDevice(int count);

  /// No description provided for @batchSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Comprezza could not save the images. Please try again.'**
  String get batchSaveFailed;

  /// No description provided for @batchShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Comprezza could not open sharing. Please try again.'**
  String get batchShareFailed;

  /// No description provided for @batchZipTitle.
  ///
  /// In en, this message translates to:
  /// **'ZIP ready'**
  String get batchZipTitle;

  /// ZIP contents summary shown in the ZIP sheet.
  ///
  /// In en, this message translates to:
  /// **'{count} files · {size}'**
  String batchZipFiles(int count, String size);

  /// No description provided for @batchZipSave.
  ///
  /// In en, this message translates to:
  /// **'Save ZIP'**
  String get batchZipSave;

  /// No description provided for @batchZipShare.
  ///
  /// In en, this message translates to:
  /// **'Share ZIP'**
  String get batchZipShare;

  /// No description provided for @batchZipSaved.
  ///
  /// In en, this message translates to:
  /// **'ZIP saved to Downloads'**
  String get batchZipSaved;

  /// No description provided for @batchZipFailed.
  ///
  /// In en, this message translates to:
  /// **'Comprezza could not build the ZIP. Please try again.'**
  String get batchZipFailed;

  /// No description provided for @batchStartOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get batchStartOver;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your compression history'**
  String get historyTitle;

  /// No description provided for @historySearch.
  ///
  /// In en, this message translates to:
  /// **'Search history'**
  String get historySearch;

  /// No description provided for @historySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Filename, preset, or output'**
  String get historySearchHint;

  /// No description provided for @historyDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get historyDate;

  /// No description provided for @historyFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get historyFormat;

  /// No description provided for @historyRatio.
  ///
  /// In en, this message translates to:
  /// **'Ratio'**
  String get historyRatio;

  /// No description provided for @historyPreset.
  ///
  /// In en, this message translates to:
  /// **'Preset'**
  String get historyPreset;

  /// No description provided for @historySort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get historySort;

  /// No description provided for @historyNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get historyNewest;

  /// No description provided for @historyOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get historyOldest;

  /// No description provided for @historyLargestFile.
  ///
  /// In en, this message translates to:
  /// **'Largest file'**
  String get historyLargestFile;

  /// No description provided for @historyAz.
  ///
  /// In en, this message translates to:
  /// **'A–Z'**
  String get historyAz;

  /// No description provided for @historyZa.
  ///
  /// In en, this message translates to:
  /// **'Z–A'**
  String get historyZa;

  /// No description provided for @historyClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get historyClearFilters;

  /// No description provided for @historyFavorites.
  ///
  /// In en, this message translates to:
  /// **'Pinned results'**
  String get historyFavorites;

  /// No description provided for @historyResults.
  ///
  /// In en, this message translates to:
  /// **'Matching sessions'**
  String get historyResults;

  /// No description provided for @historyAllSessions.
  ///
  /// In en, this message translates to:
  /// **'All sessions'**
  String get historyAllSessions;

  /// No description provided for @historySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get historySaved;

  /// No description provided for @historySavedSemantic.
  ///
  /// In en, this message translates to:
  /// **'saved'**
  String get historySavedSemantic;

  /// No description provided for @historyPin.
  ///
  /// In en, this message translates to:
  /// **'Pin result'**
  String get historyPin;

  /// No description provided for @historyUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin result'**
  String get historyUnpin;

  /// No description provided for @historyExport.
  ///
  /// In en, this message translates to:
  /// **'Export history'**
  String get historyExport;

  /// No description provided for @historyExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get historyExportCsv;

  /// No description provided for @historyExportJson.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get historyExportJson;

  /// No description provided for @historyExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get historyExportPdf;

  /// No description provided for @historyExportReady.
  ///
  /// In en, this message translates to:
  /// **'History export is ready for the approved integration.'**
  String get historyExportReady;

  /// No description provided for @historyPdfReserved.
  ///
  /// In en, this message translates to:
  /// **'PDF generation is reserved for a future export phase.'**
  String get historyPdfReserved;

  /// No description provided for @historyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete history entry?'**
  String get historyDeleteTitle;

  /// No description provided for @historyDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes the local history record. The generated image is not deleted here.'**
  String get historyDeleteMessage;

  /// No description provided for @historyDeleted.
  ///
  /// In en, this message translates to:
  /// **'History entry deleted'**
  String get historyDeleted;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your compression story starts here'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Compress a photo to begin building a private record of your storage savings.'**
  String get historyEmptyMessage;

  /// No description provided for @historyNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching sessions'**
  String get historyNoResultsTitle;

  /// No description provided for @historyNoResultsMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different filename or clear the active filters.'**
  String get historyNoResultsMessage;

  /// No description provided for @historyRatioUnderTwo.
  ///
  /// In en, this message translates to:
  /// **'Under 2×'**
  String get historyRatioUnderTwo;

  /// No description provided for @historyRatioTwoToFour.
  ///
  /// In en, this message translates to:
  /// **'2× to 4×'**
  String get historyRatioTwoToFour;

  /// No description provided for @historyRatioOverFour.
  ///
  /// In en, this message translates to:
  /// **'Over 4×'**
  String get historyRatioOverFour;

  /// No description provided for @historyBeforeImage.
  ///
  /// In en, this message translates to:
  /// **'Before image'**
  String get historyBeforeImage;

  /// No description provided for @historyAfterImage.
  ///
  /// In en, this message translates to:
  /// **'After image'**
  String get historyAfterImage;

  /// No description provided for @historyMetadataStatus.
  ///
  /// In en, this message translates to:
  /// **'Metadata status'**
  String get historyMetadataStatus;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your storage impact'**
  String get insightsTitle;

  /// No description provided for @insightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A private view of the space Comprezza has helped you reclaim.'**
  String get insightsSubtitle;

  /// No description provided for @historyThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get historyThisWeek;

  /// No description provided for @historyLifetimeSaved.
  ///
  /// In en, this message translates to:
  /// **'Lifetime saved'**
  String get historyLifetimeSaved;

  /// No description provided for @historyStorageSaved.
  ///
  /// In en, this message translates to:
  /// **'Storage saved'**
  String get historyStorageSaved;

  /// No description provided for @historyBatchSessions.
  ///
  /// In en, this message translates to:
  /// **'Batch sessions'**
  String get historyBatchSessions;

  /// No description provided for @historySavedOverTime.
  ///
  /// In en, this message translates to:
  /// **'Storage saved over time'**
  String get historySavedOverTime;

  /// No description provided for @historySavedOverTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The last seven local activity points'**
  String get historySavedOverTimeSubtitle;

  /// No description provided for @historyRatioTrend.
  ///
  /// In en, this message translates to:
  /// **'Compression ratio trend'**
  String get historyRatioTrend;

  /// No description provided for @historyRatioTrendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recent completed sessions'**
  String get historyRatioTrendSubtitle;

  /// No description provided for @historyLargestImage.
  ///
  /// In en, this message translates to:
  /// **'Largest image compressed'**
  String get historyLargestImage;

  /// No description provided for @historyLargestSaving.
  ///
  /// In en, this message translates to:
  /// **'Largest storage saving'**
  String get historyLargestSaving;

  /// No description provided for @historyAverageTime.
  ///
  /// In en, this message translates to:
  /// **'Average processing time'**
  String get historyAverageTime;

  /// No description provided for @historyMostUsedPreset.
  ///
  /// In en, this message translates to:
  /// **'Most used preset'**
  String get historyMostUsedPreset;

  /// No description provided for @historyMostUsedFormat.
  ///
  /// In en, this message translates to:
  /// **'Most used format'**
  String get historyMostUsedFormat;

  /// No description provided for @historyImageType.
  ///
  /// In en, this message translates to:
  /// **'Most common image type'**
  String get historyImageType;

  /// No description provided for @sixDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'6 days ago'**
  String get sixDaysAgo;

  /// No description provided for @historyMilestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get historyMilestones;

  /// No description provided for @achievementFirstTitle.
  ///
  /// In en, this message translates to:
  /// **'First compression'**
  String get achievementFirstTitle;

  /// No description provided for @achievementFirstDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete your first local compression.'**
  String get achievementFirstDescription;

  /// No description provided for @achievementHundredTitle.
  ///
  /// In en, this message translates to:
  /// **'100 images compressed'**
  String get achievementHundredTitle;

  /// No description provided for @achievementHundredDescription.
  ///
  /// In en, this message translates to:
  /// **'Compress 100 images on this device.'**
  String get achievementHundredDescription;

  /// No description provided for @achievementGbTitle.
  ///
  /// In en, this message translates to:
  /// **'1 GB saved'**
  String get achievementGbTitle;

  /// No description provided for @achievementGbDescription.
  ///
  /// In en, this message translates to:
  /// **'Save one gigabyte of local storage.'**
  String get achievementGbDescription;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @convertFormat.
  ///
  /// In en, this message translates to:
  /// **'Convert format'**
  String get convertFormat;

  /// No description provided for @convertFormatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'JPEG, PNG, WebP'**
  String get convertFormatSubtitle;

  /// No description provided for @resizeImage.
  ///
  /// In en, this message translates to:
  /// **'Resize image'**
  String get resizeImage;

  /// No description provided for @resizeImageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Perfect dimensions'**
  String get resizeImageSubtitle;

  /// No description provided for @benchmarkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compare settings'**
  String get benchmarkSubtitle;

  /// No description provided for @historySubtitle.
  ///
  /// In en, this message translates to:
  /// **'See your activity'**
  String get historySubtitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get settingsSubtitle;

  /// No description provided for @webReady.
  ///
  /// In en, this message translates to:
  /// **'Web ready'**
  String get webReady;

  /// No description provided for @webReadySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Small files, crisp detail'**
  String get webReadySubtitle;

  /// No description provided for @socialShare.
  ///
  /// In en, this message translates to:
  /// **'Social share'**
  String get socialShare;

  /// No description provided for @socialShareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Balanced quality and size'**
  String get socialShareSubtitle;

  /// No description provided for @lossless.
  ///
  /// In en, this message translates to:
  /// **'Lossless'**
  String get lossless;

  /// No description provided for @losslessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preserve every detail'**
  String get losslessSubtitle;

  /// No description provided for @tipWebTitle.
  ///
  /// In en, this message translates to:
  /// **'A lighter web, one image at a time'**
  String get tipWebTitle;

  /// No description provided for @tipWebMessage.
  ///
  /// In en, this message translates to:
  /// **'Use WebP for websites when you want excellent quality in a smaller file.'**
  String get tipWebMessage;

  /// No description provided for @tipScreenshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep screenshots crisp'**
  String get tipScreenshotTitle;

  /// No description provided for @tipScreenshotMessage.
  ///
  /// In en, this message translates to:
  /// **'Compress screenshots losslessly to preserve text and sharp edges.'**
  String get tipScreenshotMessage;

  /// No description provided for @tipBatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Save time in batches'**
  String get tipBatchTitle;

  /// No description provided for @tipBatchMessage.
  ///
  /// In en, this message translates to:
  /// **'When you have a full album, batch compression keeps the workflow moving.'**
  String get tipBatchMessage;

  /// No description provided for @tipMetadataTitle.
  ///
  /// In en, this message translates to:
  /// **'Metadata, your choice'**
  String get tipMetadataTitle;

  /// No description provided for @tipMetadataMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep metadata only when you need capture details to travel with the image.'**
  String get tipMetadataMessage;

  /// No description provided for @historyPlaceholderMessage.
  ///
  /// In en, this message translates to:
  /// **'Your local compression history will appear here.'**
  String get historyPlaceholderMessage;

  /// No description provided for @settingsPlaceholderMessage.
  ///
  /// In en, this message translates to:
  /// **'Personalization and preferences will live here.'**
  String get settingsPlaceholderMessage;

  /// No description provided for @benchmarkPlaceholderMessage.
  ///
  /// In en, this message translates to:
  /// **'Compare processing options when Benchmark Mode arrives.'**
  String get benchmarkPlaceholderMessage;

  /// No description provided for @aboutPlaceholderMessage.
  ///
  /// In en, this message translates to:
  /// **'Private, local, and designed to keep your moments yours.'**
  String get aboutPlaceholderMessage;

  /// No description provided for @workflowTitle.
  ///
  /// In en, this message translates to:
  /// **'Compress your image'**
  String get workflowTitle;

  /// No description provided for @workflowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A clear path from original to optimized.'**
  String get workflowSubtitle;

  /// No description provided for @workflowPresetBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get workflowPresetBalanced;

  /// No description provided for @workflowPresetBalancedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The everyday default'**
  String get workflowPresetBalancedSubtitle;

  /// No description provided for @workflowPresetMaximumQuality.
  ///
  /// In en, this message translates to:
  /// **'Maximum quality'**
  String get workflowPresetMaximumQuality;

  /// No description provided for @workflowPresetMaximumQualitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Best possible fidelity'**
  String get workflowPresetMaximumQualitySubtitle;

  /// No description provided for @workflowPresetSmallestSize.
  ///
  /// In en, this message translates to:
  /// **'Smallest size'**
  String get workflowPresetSmallestSize;

  /// No description provided for @workflowPresetSmallestSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tiny files, still clear'**
  String get workflowPresetSmallestSizeSubtitle;

  /// No description provided for @workflowPresetBadge.
  ///
  /// In en, this message translates to:
  /// **'PRESET'**
  String get workflowPresetBadge;

  /// Disclosure heading for fine-tuning compression controls.
  ///
  /// In en, this message translates to:
  /// **'Advanced options'**
  String get advancedOptions;

  /// Helper text under the advanced options disclosure.
  ///
  /// In en, this message translates to:
  /// **'Fine-tune format, dimensions, and metadata.'**
  String get advancedOptionsDescription;

  /// Secondary details under the compression result: quality percentage and output format.
  ///
  /// In en, this message translates to:
  /// **'Quality used {quality}% · Format {format}'**
  String successQualityFormat(int quality, String format);

  /// No description provided for @batchPresetBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get batchPresetBalanced;

  /// No description provided for @batchPresetBalancedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everyday default'**
  String get batchPresetBalancedSubtitle;

  /// No description provided for @batchPresetWebReady.
  ///
  /// In en, this message translates to:
  /// **'Web ready'**
  String get batchPresetWebReady;

  /// No description provided for @batchPresetWebReadySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Small files, crisp detail'**
  String get batchPresetWebReadySubtitle;

  /// No description provided for @batchPresetSmallest.
  ///
  /// In en, this message translates to:
  /// **'Smallest'**
  String get batchPresetSmallest;

  /// No description provided for @batchPresetSmallestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tiny files, still clear'**
  String get batchPresetSmallestSubtitle;

  /// Muted capability line listing supported input formats on the import surface.
  ///
  /// In en, this message translates to:
  /// **'JPEG · PNG · WebP · HEIC'**
  String get supportedFormats;

  /// No description provided for @selectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get selectFromGallery;

  /// No description provided for @useCamera.
  ///
  /// In en, this message translates to:
  /// **'Use camera'**
  String get useCamera;

  /// No description provided for @imageAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Image analysis'**
  String get imageAnalysis;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'confidence'**
  String get confidence;

  /// No description provided for @confidenceValue.
  ///
  /// In en, this message translates to:
  /// **'92%'**
  String get confidenceValue;

  /// No description provided for @compressionOptions.
  ///
  /// In en, this message translates to:
  /// **'Compression options'**
  String get compressionOptions;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @qualityDescription.
  ///
  /// In en, this message translates to:
  /// **'Balance visual quality and file size.'**
  String get qualityDescription;

  /// No description provided for @targetFileSize.
  ///
  /// In en, this message translates to:
  /// **'Target file size'**
  String get targetFileSize;

  /// No description provided for @target100Kb.
  ///
  /// In en, this message translates to:
  /// **'100 KB'**
  String get target100Kb;

  /// No description provided for @target250Kb.
  ///
  /// In en, this message translates to:
  /// **'250 KB'**
  String get target250Kb;

  /// No description provided for @target500Kb.
  ///
  /// In en, this message translates to:
  /// **'500 KB'**
  String get target500Kb;

  /// No description provided for @target1Mb.
  ///
  /// In en, this message translates to:
  /// **'1 MB'**
  String get target1Mb;

  /// No description provided for @target2Mb.
  ///
  /// In en, this message translates to:
  /// **'2 MB'**
  String get target2Mb;

  /// No description provided for @target5Mb.
  ///
  /// In en, this message translates to:
  /// **'5 MB'**
  String get target5Mb;

  /// No description provided for @outputFormat.
  ///
  /// In en, this message translates to:
  /// **'Output format'**
  String get outputFormat;

  /// No description provided for @jpegFormat.
  ///
  /// In en, this message translates to:
  /// **'JPEG'**
  String get jpegFormat;

  /// No description provided for @pngFormat.
  ///
  /// In en, this message translates to:
  /// **'PNG'**
  String get pngFormat;

  /// No description provided for @webpFormat.
  ///
  /// In en, this message translates to:
  /// **'WebP'**
  String get webpFormat;

  /// No description provided for @formatDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the format that fits where you will use it.'**
  String get formatDescription;

  /// No description provided for @resize.
  ///
  /// In en, this message translates to:
  /// **'Resize'**
  String get resize;

  /// No description provided for @resizeDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep the original dimensions or scale the image down.'**
  String get resizeDescription;

  /// No description provided for @originalDimensions.
  ///
  /// In en, this message translates to:
  /// **'Original dimensions'**
  String get originalDimensions;

  /// No description provided for @metadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get metadata;

  /// No description provided for @keepMetadata.
  ///
  /// In en, this message translates to:
  /// **'Keep metadata'**
  String get keepMetadata;

  /// No description provided for @removeMetadata.
  ///
  /// In en, this message translates to:
  /// **'Remove metadata'**
  String get removeMetadata;

  /// No description provided for @metadataDescription.
  ///
  /// In en, this message translates to:
  /// **'Removing metadata can save space and protect capture details.'**
  String get metadataDescription;

  /// No description provided for @liveEstimate.
  ///
  /// In en, this message translates to:
  /// **'Live estimate'**
  String get liveEstimate;

  /// No description provided for @estimatedSize.
  ///
  /// In en, this message translates to:
  /// **'Estimated output'**
  String get estimatedSize;

  /// No description provided for @estimatedTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Estimated time remaining'**
  String get estimatedTimeRemaining;

  /// No description provided for @estimatedSavings.
  ///
  /// In en, this message translates to:
  /// **'Estimated savings'**
  String get estimatedSavings;

  /// No description provided for @compressionRatio.
  ///
  /// In en, this message translates to:
  /// **'Compression ratio'**
  String get compressionRatio;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get original;

  /// No description provided for @compressed.
  ///
  /// In en, this message translates to:
  /// **'Compressed'**
  String get compressed;

  /// No description provided for @analysisReady.
  ///
  /// In en, this message translates to:
  /// **'Analysis complete'**
  String get analysisReady;

  /// No description provided for @compressNow.
  ///
  /// In en, this message translates to:
  /// **'Compress now'**
  String get compressNow;

  /// No description provided for @compressing.
  ///
  /// In en, this message translates to:
  /// **'Compressing your image'**
  String get compressing;

  /// No description provided for @processingImage.
  ///
  /// In en, this message translates to:
  /// **'Processing image'**
  String get processingImage;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Compression complete'**
  String get success;

  /// No description provided for @successMessage.
  ///
  /// In en, this message translates to:
  /// **'Your optimized image is ready to save or share.'**
  String get successMessage;

  /// No description provided for @saveToDevice.
  ///
  /// In en, this message translates to:
  /// **'Save to device'**
  String get saveToDevice;

  /// No description provided for @savedToPictures.
  ///
  /// In en, this message translates to:
  /// **'Saved to Pictures / Comprezza'**
  String get savedToPictures;

  /// No description provided for @openingShareSheet.
  ///
  /// In en, this message translates to:
  /// **'Opening your share sheet…'**
  String get openingShareSheet;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @compressAgain.
  ///
  /// In en, this message translates to:
  /// **'Compress again'**
  String get compressAgain;

  /// No description provided for @startOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get startOver;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @privateProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processed privately on your device'**
  String get privateProcessing;

  /// No description provided for @originalSize.
  ///
  /// In en, this message translates to:
  /// **'Original size'**
  String get originalSize;

  /// No description provided for @outputSize.
  ///
  /// In en, this message translates to:
  /// **'Output size'**
  String get outputSize;

  /// No description provided for @qualityUsed.
  ///
  /// In en, this message translates to:
  /// **'Quality used'**
  String get qualityUsed;

  /// No description provided for @formatUsed.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get formatUsed;

  /// No description provided for @processingTime.
  ///
  /// In en, this message translates to:
  /// **'Processing time'**
  String get processingTime;

  /// No description provided for @originalOption.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get originalOption;

  /// No description provided for @resize75.
  ///
  /// In en, this message translates to:
  /// **'75%'**
  String get resize75;

  /// No description provided for @resize50.
  ///
  /// In en, this message translates to:
  /// **'50%'**
  String get resize50;

  /// No description provided for @resize25.
  ///
  /// In en, this message translates to:
  /// **'25%'**
  String get resize25;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @settingsExport.
  ///
  /// In en, this message translates to:
  /// **'Export settings'**
  String get settingsExport;

  /// No description provided for @settingsExportReady.
  ///
  /// In en, this message translates to:
  /// **'A privacy-safe settings export is ready in app storage.'**
  String get settingsExportReady;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsGeneralSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make Comprezza behave the way you prefer.'**
  String get settingsGeneralSubtitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsResizeMode.
  ///
  /// In en, this message translates to:
  /// **'Default resize mode'**
  String get settingsResizeMode;

  /// No description provided for @settingsAutoAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Auto-analyze images'**
  String get settingsAutoAnalyze;

  /// No description provided for @settingsAutoRecommend.
  ///
  /// In en, this message translates to:
  /// **'Recommend compression'**
  String get settingsAutoRecommend;

  /// No description provided for @settingsRememberLast.
  ///
  /// In en, this message translates to:
  /// **'Remember last used settings'**
  String get settingsRememberLast;

  /// No description provided for @settingsOpenLastScreen.
  ///
  /// In en, this message translates to:
  /// **'Open last screen'**
  String get settingsOpenLastScreen;

  /// No description provided for @settingsCompression.
  ///
  /// In en, this message translates to:
  /// **'Compression'**
  String get settingsCompression;

  /// No description provided for @settingsCompressionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set the quality, format, and intelligence behind each workflow.'**
  String get settingsCompressionSubtitle;

  /// No description provided for @settingsAlgorithm.
  ///
  /// In en, this message translates to:
  /// **'Preferred algorithm'**
  String get settingsAlgorithm;

  /// No description provided for @settingsOutputFormat.
  ///
  /// In en, this message translates to:
  /// **'Default output format'**
  String get settingsOutputFormat;

  /// No description provided for @settingsKeepMetadata.
  ///
  /// In en, this message translates to:
  /// **'Always keep metadata'**
  String get settingsKeepMetadata;

  /// No description provided for @settingsSmartRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Smart recommendations'**
  String get settingsSmartRecommendations;

  /// No description provided for @settingsLiveEstimate.
  ///
  /// In en, this message translates to:
  /// **'Live size estimation'**
  String get settingsLiveEstimate;

  /// No description provided for @settingsBenchmark.
  ///
  /// In en, this message translates to:
  /// **'Compression benchmark'**
  String get settingsBenchmark;

  /// No description provided for @settingsTargetByDefault.
  ///
  /// In en, this message translates to:
  /// **'Compress to target size by default'**
  String get settingsTargetByDefault;

  /// No description provided for @settingsQuality.
  ///
  /// In en, this message translates to:
  /// **'Compression quality'**
  String get settingsQuality;

  /// No description provided for @settingsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// No description provided for @settingsStorageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep generated files tidy and predictable.'**
  String get settingsStorageSubtitle;

  /// No description provided for @settingsAutoDeleteTemporary.
  ///
  /// In en, this message translates to:
  /// **'Auto-delete temporary files'**
  String get settingsAutoDeleteTemporary;

  /// No description provided for @settingsCleanupInterval.
  ///
  /// In en, this message translates to:
  /// **'Cleanup interval'**
  String get settingsCleanupInterval;

  /// No description provided for @settingsMaximumCache.
  ///
  /// In en, this message translates to:
  /// **'Maximum cache size'**
  String get settingsMaximumCache;

  /// No description provided for @settingsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get settingsClearCache;

  /// No description provided for @settingsClearCacheMessage.
  ///
  /// In en, this message translates to:
  /// **'Only generated app cache will be removed. Original photos are never touched.'**
  String get settingsClearCacheMessage;

  /// No description provided for @settingsClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get settingsClearHistory;

  /// No description provided for @settingsClearHistoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove local compression history metadata? Generated exports are not deleted.'**
  String get settingsClearHistoryMessage;

  /// No description provided for @settingsResetStorage.
  ///
  /// In en, this message translates to:
  /// **'Reset storage'**
  String get settingsResetStorage;

  /// No description provided for @settingsResetStorageMessage.
  ///
  /// In en, this message translates to:
  /// **'Clear generated cache and local history metadata from this device.'**
  String get settingsResetStorageMessage;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tune the visual rhythm for your device and your eyes.'**
  String get settingsAppearanceSubtitle;

  /// No description provided for @settingsDynamicColors.
  ///
  /// In en, this message translates to:
  /// **'Material You dynamic colors'**
  String get settingsDynamicColors;

  /// No description provided for @settingsAdaptiveIcons.
  ///
  /// In en, this message translates to:
  /// **'Adaptive icons'**
  String get settingsAdaptiveIcons;

  /// No description provided for @settingsLargeUi.
  ///
  /// In en, this message translates to:
  /// **'Large UI mode'**
  String get settingsLargeUi;

  /// No description provided for @settingsCompactUi.
  ///
  /// In en, this message translates to:
  /// **'Compact UI mode'**
  String get settingsCompactUi;

  /// No description provided for @settingsAnimationSpeed.
  ///
  /// In en, this message translates to:
  /// **'Animation speed'**
  String get settingsAnimationSpeed;

  /// No description provided for @settingsFontScaling.
  ///
  /// In en, this message translates to:
  /// **'Font scaling'**
  String get settingsFontScaling;

  /// No description provided for @settingsAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get settingsAccessibility;

  /// No description provided for @settingsAccessibilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Comfortable controls, clear feedback, and strong semantics.'**
  String get settingsAccessibilitySubtitle;

  /// No description provided for @settingsScreenReaders.
  ///
  /// In en, this message translates to:
  /// **'Screen reader support'**
  String get settingsScreenReaders;

  /// No description provided for @settingsHighContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get settingsHighContrast;

  /// No description provided for @settingsLargeTouchTargets.
  ///
  /// In en, this message translates to:
  /// **'Large touch targets'**
  String get settingsLargeTouchTargets;

  /// No description provided for @settingsDynamicText.
  ///
  /// In en, this message translates to:
  /// **'Dynamic text scaling'**
  String get settingsDynamicText;

  /// No description provided for @settingsReduceAnimations.
  ///
  /// In en, this message translates to:
  /// **'Reduce animations'**
  String get settingsReduceAnimations;

  /// No description provided for @settingsColorBlindPalette.
  ///
  /// In en, this message translates to:
  /// **'Color-blind friendly palette'**
  String get settingsColorBlindPalette;

  /// No description provided for @settingsProgressAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Progress announcements'**
  String get settingsProgressAnnouncements;

  /// No description provided for @settingsSemanticLabels.
  ///
  /// In en, this message translates to:
  /// **'Semantic labels'**
  String get settingsSemanticLabels;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your privacy baseline is always visible and always local.'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsOfflineProcessing.
  ///
  /// In en, this message translates to:
  /// **'Offline processing'**
  String get settingsOfflineProcessing;

  /// No description provided for @settingsNoCloudUpload.
  ///
  /// In en, this message translates to:
  /// **'No cloud uploads'**
  String get settingsNoCloudUpload;

  /// No description provided for @settingsNoAnalytics.
  ///
  /// In en, this message translates to:
  /// **'No analytics'**
  String get settingsNoAnalytics;

  /// No description provided for @settingsNoTracking.
  ///
  /// In en, this message translates to:
  /// **'No tracking'**
  String get settingsNoTracking;

  /// No description provided for @settingsPrivacyAlwaysOn.
  ///
  /// In en, this message translates to:
  /// **'Always on in Comprezza'**
  String get settingsPrivacyAlwaysOn;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Open-source libraries'**
  String get settingsOpenSource;

  /// No description provided for @settingsAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get settingsAdvanced;

  /// No description provided for @settingsAdvancedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import, export, diagnostics, and carefully gated controls.'**
  String get settingsAdvancedSubtitle;

  /// No description provided for @settingsBenchmarkMode.
  ///
  /// In en, this message translates to:
  /// **'Benchmark mode'**
  String get settingsBenchmarkMode;

  /// No description provided for @settingsDeveloperLogging.
  ///
  /// In en, this message translates to:
  /// **'Developer logging'**
  String get settingsDeveloperLogging;

  /// No description provided for @settingsVerboseLogging.
  ///
  /// In en, this message translates to:
  /// **'Verbose logging (debug only)'**
  String get settingsVerboseLogging;

  /// No description provided for @settingsExportConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Export configuration'**
  String get settingsExportConfiguration;

  /// No description provided for @settingsImportConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Import configuration'**
  String get settingsImportConfiguration;

  /// No description provided for @settingsImportDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a Comprezza settings export from app-private storage. Sensitive paths and debug data are excluded.'**
  String get settingsImportDescription;

  /// No description provided for @settingsFactoryReset.
  ///
  /// In en, this message translates to:
  /// **'Factory reset'**
  String get settingsFactoryReset;

  /// No description provided for @settingsFactoryResetMessage.
  ///
  /// In en, this message translates to:
  /// **'Reset preferences and remove generated cache and local history metadata? This cannot be undone.'**
  String get settingsFactoryResetMessage;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Comprezza, by Dzynova Technologies.'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get settingsWebsite;

  /// No description provided for @settingsDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Dzynova Technologies'**
  String get settingsDeveloper;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsBuildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build number'**
  String get settingsBuildNumber;

  /// No description provided for @settingsRateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate Comprezza'**
  String get settingsRateApp;

  /// No description provided for @settingsShareApp.
  ///
  /// In en, this message translates to:
  /// **'Share Comprezza'**
  String get settingsShareApp;

  /// No description provided for @settingsChangelog.
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get settingsChangelog;

  /// No description provided for @settingsDeveloperOptions.
  ///
  /// In en, this message translates to:
  /// **'Developer options'**
  String get settingsDeveloperOptions;

  /// No description provided for @settingsDeveloperOptionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlocked locally in debug builds. Never shown in release mode.'**
  String get settingsDeveloperOptionsSubtitle;

  /// No description provided for @settingsViewEngineStatus.
  ///
  /// In en, this message translates to:
  /// **'View engine status'**
  String get settingsViewEngineStatus;

  /// No description provided for @settingsViewQueueStatus.
  ///
  /// In en, this message translates to:
  /// **'View queue status'**
  String get settingsViewQueueStatus;

  /// No description provided for @settingsViewCacheStatus.
  ///
  /// In en, this message translates to:
  /// **'View cache status'**
  String get settingsViewCacheStatus;

  /// No description provided for @settingsPerformanceMonitor.
  ///
  /// In en, this message translates to:
  /// **'Performance monitor'**
  String get settingsPerformanceMonitor;

  /// No description provided for @settingsFrameStatistics.
  ///
  /// In en, this message translates to:
  /// **'Frame rendering statistics'**
  String get settingsFrameStatistics;

  /// No description provided for @settingsMemoryStatistics.
  ///
  /// In en, this message translates to:
  /// **'Memory statistics'**
  String get settingsMemoryStatistics;

  /// No description provided for @settingsDependencyGraph.
  ///
  /// In en, this message translates to:
  /// **'Dependency graph'**
  String get settingsDependencyGraph;

  /// No description provided for @settingsCompressionBenchmark.
  ///
  /// In en, this message translates to:
  /// **'Compression benchmark'**
  String get settingsCompressionBenchmark;

  /// No description provided for @settingsExperimentalFeatures.
  ///
  /// In en, this message translates to:
  /// **'Experimental features'**
  String get settingsExperimentalFeatures;

  /// No description provided for @settingsFeatureFlags.
  ///
  /// In en, this message translates to:
  /// **'Feature flags'**
  String get settingsFeatureFlags;

  /// No description provided for @settingsStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get settingsStatusReady;

  /// No description provided for @settingsStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get settingsStatusIdle;

  /// No description provided for @settingsStatusProtected.
  ///
  /// In en, this message translates to:
  /// **'Protected'**
  String get settingsStatusProtected;

  /// No description provided for @settingsStatusLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Local only'**
  String get settingsStatusLocalOnly;

  /// No description provided for @settingsStatusDebugOnly.
  ///
  /// In en, this message translates to:
  /// **'Debug only'**
  String get settingsStatusDebugOnly;

  /// No description provided for @settingsResetAppearance.
  ///
  /// In en, this message translates to:
  /// **'Reset appearance'**
  String get settingsResetAppearance;

  /// No description provided for @settingsResetCompression.
  ///
  /// In en, this message translates to:
  /// **'Reset compression'**
  String get settingsResetCompression;

  /// No description provided for @settingsResetRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Reset recommendations'**
  String get settingsResetRecommendations;

  /// No description provided for @settingsResetAppearanceMessage.
  ///
  /// In en, this message translates to:
  /// **'Restore the default appearance preferences?'**
  String get settingsResetAppearanceMessage;

  /// No description provided for @settingsResetCompressionMessage.
  ///
  /// In en, this message translates to:
  /// **'Restore the default compression preferences?'**
  String get settingsResetCompressionMessage;

  /// No description provided for @settingsResetRecommendationsMessage.
  ///
  /// In en, this message translates to:
  /// **'Restore the default recommendation preferences?'**
  String get settingsResetRecommendationsMessage;

  /// No description provided for @settingsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsReset;

  /// No description provided for @settingsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get settingsConfirm;

  /// No description provided for @settingsSystemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsSystemTheme;

  /// No description provided for @settingsLightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsLightTheme;

  /// No description provided for @settingsDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsDarkTheme;

  /// No description provided for @settingsOriginalResize.
  ///
  /// In en, this message translates to:
  /// **'Original dimensions'**
  String get settingsOriginalResize;

  /// No description provided for @settingsAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get settingsAutomatic;

  /// No description provided for @settingsNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get settingsNever;

  /// No description provided for @settingsDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get settingsDaily;

  /// No description provided for @settingsWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get settingsWeekly;

  /// No description provided for @settingsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get settingsMonthly;

  /// No description provided for @settingsFullMotion.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get settingsFullMotion;

  /// No description provided for @settingsReducedMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduced'**
  String get settingsReducedMotion;

  /// No description provided for @settingsMotionOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsMotionOff;

  /// No description provided for @settingsHeroSemantic.
  ///
  /// In en, this message translates to:
  /// **'Settings personalization overview'**
  String get settingsHeroSemantic;

  /// No description provided for @settingsHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Comprezza'**
  String get settingsHeroTitle;

  /// No description provided for @settingsHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Private photo compression.'**
  String get settingsHeroSubtitle;

  /// No description provided for @settingsRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get settingsRecommendations;

  /// No description provided for @settingsRecommendationLargeCache.
  ///
  /// In en, this message translates to:
  /// **'Large cache detected'**
  String get settingsRecommendationLargeCache;

  /// No description provided for @settingsRecommendationLargeCacheMessage.
  ///
  /// In en, this message translates to:
  /// **'Consider clearing generated cache to reclaim local storage.'**
  String get settingsRecommendationLargeCacheMessage;

  /// No description provided for @settingsRecommendationScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots are frequent'**
  String get settingsRecommendationScreenshots;

  /// No description provided for @settingsRecommendationScreenshotsMessage.
  ///
  /// In en, this message translates to:
  /// **'A PNG preset can keep text and sharp edges crisp.'**
  String get settingsRecommendationScreenshotsMessage;

  /// No description provided for @settingsRecommendationPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos are frequent'**
  String get settingsRecommendationPhotos;

  /// No description provided for @settingsRecommendationPhotosMessage.
  ///
  /// In en, this message translates to:
  /// **'A JPEG preset is a balanced default for photos.'**
  String get settingsRecommendationPhotosMessage;

  /// No description provided for @settingsRecommendationWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website images are frequent'**
  String get settingsRecommendationWebsite;

  /// No description provided for @settingsRecommendationWebsiteMessage.
  ///
  /// In en, this message translates to:
  /// **'WebP can reduce file size while preserving web-ready quality.'**
  String get settingsRecommendationWebsiteMessage;

  /// No description provided for @settingsRecommendationLowStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage is running low'**
  String get settingsRecommendationLowStorage;

  /// No description provided for @settingsRecommendationLowStorageMessage.
  ///
  /// In en, this message translates to:
  /// **'Enable automatic cleanup and keep temporary files short-lived.'**
  String get settingsRecommendationLowStorageMessage;

  /// No description provided for @settingsRecommendationGeneric.
  ///
  /// In en, this message translates to:
  /// **'A local optimization is available'**
  String get settingsRecommendationGeneric;

  /// No description provided for @settingsRecommendationGenericMessage.
  ///
  /// In en, this message translates to:
  /// **'Review your settings to keep this device tidy.'**
  String get settingsRecommendationGenericMessage;

  /// A percentage value shown in settings.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String settingsPercentValue(int value);

  /// A cache size shown in settings.
  ///
  /// In en, this message translates to:
  /// **'{value} MB'**
  String settingsMegabytesValue(int value);

  /// No description provided for @settingsPrivacyPolicyDescription.
  ///
  /// In en, this message translates to:
  /// **'Comprezza processes selected images locally and does not intentionally upload them. The published policy must be reviewed before release.'**
  String get settingsPrivacyPolicyDescription;

  /// No description provided for @settingsOpenSourceDescription.
  ///
  /// In en, this message translates to:
  /// **'This screen uses Flutter and the packages listed in the project license notices.'**
  String get settingsOpenSourceDescription;

  /// No description provided for @settingsChangelogDescription.
  ///
  /// In en, this message translates to:
  /// **'Review the project changelog for transparent release and architecture notes.'**
  String get settingsChangelogDescription;

  /// No description provided for @settingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Settings could not be loaded. Defaults are being used.'**
  String get settingsLoadFailed;

  /// No description provided for @settingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Settings could not be saved. Your last saved values were restored.'**
  String get settingsSaveFailed;

  /// No description provided for @settingsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Settings export could not be created.'**
  String get settingsExportFailed;

  /// No description provided for @settingsImportFailed.
  ///
  /// In en, this message translates to:
  /// **'That settings export could not be imported.'**
  String get settingsImportFailed;

  /// No description provided for @settingsStorageActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The storage action could not be completed.'**
  String get settingsStorageActionFailed;

  /// No description provided for @settingsRemoveMetadata.
  ///
  /// In en, this message translates to:
  /// **'Always remove metadata'**
  String get settingsRemoveMetadata;

  /// No description provided for @settingsQualityPreview.
  ///
  /// In en, this message translates to:
  /// **'Compression quality preview'**
  String get settingsQualityPreview;

  /// No description provided for @settingsHistorySizeLimit.
  ///
  /// In en, this message translates to:
  /// **'Compression history size limit'**
  String get settingsHistorySizeLimit;

  /// No description provided for @settingsErrorAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Error announcements'**
  String get settingsErrorAnnouncements;

  /// No description provided for @settingsNoUserAccounts.
  ///
  /// In en, this message translates to:
  /// **'No user accounts'**
  String get settingsNoUserAccounts;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get settingsTerms;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get settingsLicenses;

  /// No description provided for @settingsAcknowledgements.
  ///
  /// In en, this message translates to:
  /// **'Acknowledgements'**
  String get settingsAcknowledgements;

  /// A target size shown in settings.
  ///
  /// In en, this message translates to:
  /// **'{value} KB'**
  String settingsKilobytesValue(int value);

  /// A history item limit shown in settings.
  ///
  /// In en, this message translates to:
  /// **'{value} items'**
  String settingsItemsValue(int value);

  /// No description provided for @settingsTermsDescription.
  ///
  /// In en, this message translates to:
  /// **'Review the terms that govern use of Comprezza.'**
  String get settingsTermsDescription;

  /// No description provided for @settingsLicensesDescription.
  ///
  /// In en, this message translates to:
  /// **'Review the open-source license notices included with Comprezza.'**
  String get settingsLicensesDescription;

  /// No description provided for @settingsAcknowledgementsDescription.
  ///
  /// In en, this message translates to:
  /// **'Comprezza is built with the Flutter ecosystem and its open-source contributors.'**
  String get settingsAcknowledgementsDescription;

  /// No description provided for @settingsDefaultPreset.
  ///
  /// In en, this message translates to:
  /// **'Default compression preset'**
  String get settingsDefaultPreset;

  /// No description provided for @settingsBalancedPreset.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get settingsBalancedPreset;

  /// No description provided for @settingsWebPreset.
  ///
  /// In en, this message translates to:
  /// **'Web'**
  String get settingsWebPreset;

  /// No description provided for @settingsLosslessPreset.
  ///
  /// In en, this message translates to:
  /// **'Lossless'**
  String get settingsLosslessPreset;

  /// No description provided for @settingsDefaultTarget.
  ///
  /// In en, this message translates to:
  /// **'Default target file size'**
  String get settingsDefaultTarget;

  /// No description provided for @settingsNoTarget.
  ///
  /// In en, this message translates to:
  /// **'No target'**
  String get settingsNoTarget;

  /// No description provided for @settingsAutoDeleteOldHistory.
  ///
  /// In en, this message translates to:
  /// **'Auto-delete old history'**
  String get settingsAutoDeleteOldHistory;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notification controls are ready for a future local integration.'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsNotificationsFutureReady.
  ///
  /// In en, this message translates to:
  /// **'Future-ready notification controls'**
  String get settingsNotificationsFutureReady;

  /// No description provided for @settingsNotificationsFutureReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'No notifications are enabled yet.'**
  String get settingsNotificationsFutureReadyMessage;

  /// No description provided for @settingsStorageOverview.
  ///
  /// In en, this message translates to:
  /// **'Storage usage overview'**
  String get settingsStorageOverview;

  /// A storage usage summary shown in settings.
  ///
  /// In en, this message translates to:
  /// **'Using {value} across Comprezza storage'**
  String settingsStorageOverviewValue(String value);

  /// No description provided for @settingsDisplayDensity.
  ///
  /// In en, this message translates to:
  /// **'Display density'**
  String get settingsDisplayDensity;

  /// No description provided for @settingsComfortableDensity.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get settingsComfortableDensity;

  /// No description provided for @settingsCompactDensity.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get settingsCompactDensity;

  /// No description provided for @settingsStorageCache.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get settingsStorageCache;

  /// No description provided for @settingsStorageTemporary.
  ///
  /// In en, this message translates to:
  /// **'Temporary files'**
  String get settingsStorageTemporary;

  /// No description provided for @settingsStorageHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get settingsStorageHistory;

  /// No description provided for @settingsStorageExports.
  ///
  /// In en, this message translates to:
  /// **'Exports'**
  String get settingsStorageExports;

  /// Primary action for starting a compression benchmark.
  ///
  /// In en, this message translates to:
  /// **'Choose an image'**
  String get benchmarkChooseImage;

  /// Primary action to re-run the compression benchmark.
  ///
  /// In en, this message translates to:
  /// **'Run benchmark'**
  String get benchmarkRun;

  /// Progress label shown while the benchmark compresses an image.
  ///
  /// In en, this message translates to:
  /// **'Benchmarking compression…'**
  String get benchmarkRunning;

  /// Empty state title for the benchmark screen.
  ///
  /// In en, this message translates to:
  /// **'No benchmark yet'**
  String get benchmarkEmptyTitle;

  /// Empty state message for the benchmark screen.
  ///
  /// In en, this message translates to:
  /// **'Pick a photo and Comprezza will compare how each quality setting changes time and size — privately, on this device.'**
  String get benchmarkEmptyMessage;

  /// Section heading for completed benchmark results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get benchmarkResults;

  /// Section heading for per-quality comparison rows.
  ///
  /// In en, this message translates to:
  /// **'Quality comparison'**
  String get benchmarkComparison;

  /// Label for the fastest benchmark run.
  ///
  /// In en, this message translates to:
  /// **'Fastest run'**
  String get benchmarkFastest;

  /// Label for the best compression ratio achieved.
  ///
  /// In en, this message translates to:
  /// **'Best ratio'**
  String get benchmarkBestRatio;

  /// Label for total bytes saved across benchmark runs.
  ///
  /// In en, this message translates to:
  /// **'Total saved'**
  String get benchmarkTotalSaved;

  /// Label for measured throughput.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get benchmarkSpeed;

  /// Label for a measured duration.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get benchmarkTime;

  /// Section heading for legal rows on the About screen.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get aboutLegal;

  /// Error message when persisted history cannot be read.
  ///
  /// In en, this message translates to:
  /// **'Your compression history could not be loaded.'**
  String get historyLoadFailed;

  /// Feedback shown when sharing a history record is not yet available.
  ///
  /// In en, this message translates to:
  /// **'Sharing generated files is reserved for a future integration.'**
  String get historyShareReserved;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
