import 'package:comprezza/features/compressor/presentation/batch_compression_controller.dart';
import 'package:comprezza/features/compressor/presentation/batch_compression_screen.dart';
import 'package:comprezza/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BatchImageItem image(String id) => BatchImageItem(
    id: id,
    path: '/missing/$id.jpg',
    name: '$id.jpg',
    width: 2400,
    height: 1600,
    format: 'JPEG',
  );

  Widget host(
    BatchCompressionController controller, {
    Size size = const Size(390, 844),
  }) {
    return MediaQuery(
      data: MediaQueryData(size: size, disableAnimations: true),
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BatchCompressionScreen(controller: controller),
      ),
    );
  }

  BatchCompressionController controller() => BatchCompressionController(
    picker: () async => <BatchImageItem>[image('picked')],
    processor: (BatchImageItem item, BatchCompressionSettings settings) async =>
        BatchImageResult(
          outputPath: '${item.path}.compressed',
          outputBytes: 600 * 1024,
        ),
  );

  testWidgets('shows an accessible empty state and selects images', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final BatchCompressionController featureController = controller();
    addTearDown(featureController.dispose);
    await tester.pumpWidget(host(featureController));

    expect(find.text('Compress a batch'), findsOneWidget);
    expect(find.text('Select multiple images'), findsOneWidget);
    // The step indicator announces the current workflow step accessibly.
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is Semantics &&
            widget.properties.label == 'Select' &&
            widget.properties.value != null,
      ),
      findsWidgets,
    );

    await tester.tap(find.text('Select multiple images'));
    await tester.pump();

    expect(find.text('picked.jpg'), findsOneWidget);
    expect(find.text('Select all'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'renders settings without phone overflow and supports start over',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final BatchCompressionController featureController = controller();
      addTearDown(featureController.dispose);
      featureController.addImages(<BatchImageItem>[image('one'), image('two')]);
      featureController.openSettings();
      await tester.pumpWidget(host(featureController));

      // The settings panel header and the action bar both label the primary
      // action, so at least one is always present on screen.
      expect(find.text('Apply settings'), findsWidgets);
      expect(find.text('Output format'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Start over'));
      await tester.pump();
      expect(find.text('Start with a group of photos'), findsOneWidget);
    },
  );

  testWidgets('shows completion summary and retry action after a failure', (
    WidgetTester tester,
  ) async {
    var shouldFail = true;
    final BatchCompressionController featureController =
        BatchCompressionController(
          picker: () async => <BatchImageItem>[],
          processor:
              (BatchImageItem item, BatchCompressionSettings settings) async {
                if (shouldFail) {
                  shouldFail = false;
                  throw StateError('temporary failure');
                }
                return const BatchImageResult(
                  outputPath: '/missing/output.jpg',
                  outputBytes: 500,
                );
              },
        );
    addTearDown(featureController.dispose);
    featureController.addImages(<BatchImageItem>[image('retry')]);
    await tester.pumpWidget(
      host(featureController, size: const Size(1000, 800)),
    );
    // The controller's analysis loop yields via a zero-duration timer, which
    // only fires when the fake-async clock advances. Run the real async work
    // outside the fake zone, then re-pump to render the completed state.
    await tester.runAsync(featureController.startProcessing);
    await tester.pump();

    expect(find.text('Batch complete'), findsOneWidget);
    // The retry action lives in the last sliver of the scroll view, so it is
    // built lazily and must be scrolled into view before it can be asserted
    // or tapped.
    await tester.scrollUntilVisible(
      find.text('Retry failed'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // The action bar can be built just below the fold; bring it fully on
    // screen so the tap lands inside the render tree.
    await tester.ensureVisible(find.text('Retry failed').first);
    await tester.pump();
    expect(find.text('Retry failed'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Retry failed').first);
    await tester.pump();
    expect(featureController.completedCount, 1);
  });

  testWidgets(
    'regression: processing driven through the widget completes in bounded time',
    (WidgetTester tester) async {
      // Regression guard for the fake-async freeze that originally hung the
      // whole suite: awaiting controller work that yields on zero-duration
      // timers inside a testWidgets zone never completes because those timers
      // only fire when the test clock advances. runAsync executes the work
      // with real timers, and the real-time timeout turns any future
      // never-completing controller change into a fast failure.
      final BatchCompressionController featureController = controller();
      addTearDown(featureController.dispose);
      featureController.addImages(<BatchImageItem>[image('regression')]);
      await tester.pumpWidget(host(featureController));

      await tester.runAsync(
        () => featureController.startProcessing().timeout(
          const Duration(seconds: 5),
        ),
      );
      await tester.pump();

      expect(featureController.phase, BatchWorkflowPhase.completed);
      expect(featureController.completedCount, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'completed batch drives save-all, share-selected, and ZIP actions',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final List<String> saved = <String>[];
      final List<String> shared = <String>[];
      final List<String> savedZips = <String>[];
      const BatchZipResult zip = BatchZipResult(
        path: '/tmp/comprezza_batch.zip',
        name: 'Comprezza_20260809.zip',
        bytes: 4096,
        fileCount: 1,
      );
      final BatchCompressionController featureController =
          BatchCompressionController(
            picker: () async => <BatchImageItem>[image('one'), image('two')],
            processor:
                (
                  BatchImageItem item,
                  BatchCompressionSettings settings,
                ) async => BatchImageResult(
                  outputPath: '${item.path}.compressed',
                  outputBytes: 600 * 1024,
                ),
            saveAllHandler: (List<String> paths) async => saved.addAll(paths),
            shareHandler: (List<String> paths) async => shared.addAll(paths),
            zipBuilder: (List<String> paths) async => zip,
            zipSaver: (String path) async => savedZips.add(path),
          );
      addTearDown(featureController.dispose);
      featureController.addImages(<BatchImageItem>[image('one'), image('two')]);
      await tester.pumpWidget(host(featureController));
      await tester.runAsync(
        () => featureController.startProcessing().timeout(
          const Duration(seconds: 5),
        ),
      );
      await tester.pump();

      // The action bar lives in the last sliver; scroll it into view first.
      await tester.scrollUntilVisible(
        find.text('Save all'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Save all'), findsWidgets);

      // Save all persists every completed output through the gallery seam.
      await tester.tap(find.text('Save all').first);
      await tester.pump();
      await tester.pump();
      expect(saved, hasLength(2));
      expect(find.textContaining('Saved 2 images'), findsOneWidget);

      // Share selected dispatches outputs through the share seam.
      await tester.tap(find.text('Share selected').first);
      await tester.pump();
      await tester.pump();
      expect(shared, hasLength(2));
      expect(find.textContaining('Opening your share sheet'), findsOneWidget);

      // Prepare ZIP presents the archive with its save/share actions.
      await tester.tap(find.text('Prepare ZIP').first);
      await tester.pumpAndSettle();
      expect(find.text('ZIP ready'), findsOneWidget);
      expect(find.text('Comprezza_20260809.zip'), findsOneWidget);
      expect(find.text('1 files · 4.0 KB'), findsOneWidget);

      // Share ZIP routes the archive through the share seam.
      await tester.tap(find.text('Share ZIP'));
      await tester.pumpAndSettle();
      expect(shared, hasLength(3));
      expect(shared.last, '/tmp/comprezza_batch.zip');

      // Reopen the sheet and save the ZIP through its persistence seam.
      await tester.tap(find.text('Prepare ZIP').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save ZIP'));
      // The sheet pop and the previous snackbar's exit both animate, so settle
      // through them before asserting the new confirmation snackbar.
      await tester.pumpAndSettle();
      expect(savedZips, equals(<String>['/tmp/comprezza_batch.zip']));
      expect(find.text('ZIP saved to Downloads'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('batch action failures surface human error snackbars', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final BatchCompressionController featureController =
        BatchCompressionController(
          picker: () async => const <BatchImageItem>[],
          processor:
              (BatchImageItem item, BatchCompressionSettings settings) async =>
                  BatchImageResult(
                    outputPath: '${item.path}.compressed',
                    outputBytes: 400,
                  ),
          saveAllHandler: (List<String> paths) async {
            throw StateError('gallery busy');
          },
          zipBuilder: (List<String> paths) async {
            throw StateError('disk full');
          },
        );
    addTearDown(featureController.dispose);
    featureController.addImages(<BatchImageItem>[image('one')]);
    await tester.pumpWidget(host(featureController));
    await tester.runAsync(
      () => featureController.startProcessing().timeout(
        const Duration(seconds: 5),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Save all'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    // A failing gallery seam surfaces the human save error, not a crash.
    await tester.tap(find.text('Save all').first);
    await tester.pump();
    await tester.pump();
    expect(
      find.text('Comprezza could not save the images. Please try again.'),
      findsOneWidget,
    );

    // A failing ZIP builder surfaces the human ZIP error.
    await tester.tap(find.text('Prepare ZIP').first);
    await tester.pump();
    await tester.pump();
    expect(
      find.text('Comprezza could not build the ZIP. Please try again.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
