import 'package:comprezza/features/compressor/domain/entities/application_entities.dart';
import 'package:comprezza/features/compressor/presentation/history_insights_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HistoryEntry entry(
    String id, {
    required DateTime date,
    String name = 'photo.jpg',
    int input = 10 * 1024,
    int output = 4 * 1024,
    int files = 1,
    String preset = 'Balanced',
    ImageFormat format = ImageFormat.jpeg,
  }) {
    return HistoryEntry(
      id: id,
      sourceName: name,
      outputName: '$id.webp',
      createdAt: date,
      preset: CompressionPreset(
        id: preset.toLowerCase(),
        name: preset,
        quality: 72,
        format: format,
      ),
      statistics: CompressionStatistics(
        inputBytes: input,
        outputBytes: output,
        savedBytes: input - output,
        savingsRatio: input / output,
        processedFiles: files,
        duration: const Duration(milliseconds: 400),
      ),
      outputPath: '/outputs/$id.webp',
    );
  }

  test(
    'filters, sorts, and toggles favorites without mutating source records',
    () {
      final HistoryInsightsController controller = HistoryInsightsController(
        entries: <HistoryEntry>[
          entry('new', date: DateTime(2026, 8, 6), name: 'new.jpg'),
          entry(
            'old',
            date: DateTime(2026, 7),
            name: 'old.png',
            output: 8 * 1024,
            format: ImageFormat.png,
          ),
        ],
      );
      addTearDown(controller.dispose);
      controller.initialize();

      expect(controller.entries.first.id, 'new');
      controller.setQuery('old');
      expect(controller.entries.single.id, 'old');
      controller.clearFilters();
      controller.setSortOrder(HistorySortOrder.largestSaving);
      expect(controller.entries.first.id, 'new');
      controller.toggleFavorite('new');
      expect(controller.favorites.single.id, 'new');
    },
  );

  test('calculates aggregate insights from all records', () {
    final HistoryInsightsController controller = HistoryInsightsController(
      entries: <HistoryEntry>[
        entry('one', date: DateTime.now(), files: 3, preset: 'Web ready'),
        entry(
          'two',
          date: DateTime.now(),
          input: 20 * 1024,
          output: 5 * 1024,
          preset: 'Web ready',
        ),
      ],
    );
    addTearDown(controller.dispose);
    controller.initialize();

    final HistoryInsights insights = controller.insights;
    expect(insights.imagesCompressed, 4);
    expect(insights.lifetimeSaved, 21 * 1024);
    expect(insights.mostUsedPreset, 'Web ready');
    expect(insights.batchSessionsCompleted, 1);
    expect(insights.savedByDay, hasLength(7));
    expect(insights.ratioBySession, hasLength(2));
  });

  test('deletion hides entries and undo restores them', () async {
    final List<String> deleted = <String>[];
    final List<String> restored = <String>[];
    final HistoryEntry value = entry('one', date: DateTime.now());
    final HistoryInsightsController controller = HistoryInsightsController(
      entries: <HistoryEntry>[value],
      onDelete: (HistoryEntry item) async => deleted.add(item.id),
      onRestore: (HistoryEntry item) async => restored.add(item.id),
    );
    addTearDown(controller.dispose);
    controller.initialize();

    await controller.deleteEntry(value);
    expect(controller.entries, isEmpty);
    expect(deleted, <String>['one']);
    await controller.undoLastDelete();
    expect(controller.entries.single.id, 'one');
    expect(restored, <String>['one']);
    expect(controller.insights.imagesCompressed, 1);
  });

  test('favorites remain available while another filter is active', () {
    final HistoryEntry value = entry(
      'one',
      date: DateTime.now(),
      name: 'one.jpg',
    );
    final HistoryInsightsController controller = HistoryInsightsController(
      entries: <HistoryEntry>[value],
    );
    addTearDown(controller.dispose);
    controller.initialize();

    controller.toggleFavorite(value.id);
    controller.setQuery('no match');
    expect(controller.entries, isEmpty);
    expect(controller.favorites.single.id, value.id);
  });

  test('export seam receives requested report format', () async {
    HistoryExportFormat? requested;
    final HistoryInsightsController controller = HistoryInsightsController(
      onExport: (HistoryExportFormat format) async => requested = format,
    );
    addTearDown(controller.dispose);

    await controller.export(HistoryExportFormat.json);
    expect(requested, HistoryExportFormat.json);
  });
}
