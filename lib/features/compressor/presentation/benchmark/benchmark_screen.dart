import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../../core/services/benchmark_timer.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/compression_models.dart';
import '../../domain/gateways/compressor_gateways.dart';
import '../design_system/design_system.dart';

/// One measured compression run at a fixed quality.
final class BenchmarkRun {
  /// Creates a benchmark run.
  const BenchmarkRun({
    required this.quality,
    required this.elapsed,
    required this.inputBytes,
    required this.outputBytes,
  });

  /// JPEG quality used for this run.
  final int quality;

  /// Measured wall-clock duration.
  final Duration elapsed;

  /// Source size in bytes.
  final int inputBytes;

  /// Compressed size in bytes.
  final int outputBytes;

  /// Bytes saved by this run (never negative).
  int get savedBytes => (inputBytes - outputBytes).clamp(0, inputBytes);

  /// Original-to-output ratio; zero when there is no output.
  double get ratio => outputBytes <= 0 ? 0 : inputBytes / outputBytes;

  /// Throughput in bytes per second.
  double get bytesPerSecond {
    final double seconds = elapsed.inMicroseconds / 1000000;
    return seconds <= 0 ? 0 : inputBytes / seconds;
  }
}

/// Lifecycle of the on-device compression benchmark.
enum BenchmarkStatus { idle, running, done, error }

/// Coordinates a real compression benchmark using the same gateways the
/// compression workflow runs on: one picked photo is compressed at several
/// quality levels while [BenchmarkTimer] records each run.
final class BenchmarkController extends ChangeNotifier {
  /// Creates a benchmark controller.
  BenchmarkController({
    required ImagePickerGateway pickerGateway,
    required ImageCompressionGateway compressionGateway,
    required BenchmarkTimer timer,
    List<int> qualities = const <int>[50, 72, 90],
  }) : _pickerGateway = pickerGateway,
       _compressionGateway = compressionGateway,
       _timer = timer,
       _qualities = qualities;

  final ImagePickerGateway _pickerGateway;
  final ImageCompressionGateway _compressionGateway;
  final BenchmarkTimer _timer;
  final List<int> _qualities;

  BenchmarkStatus _status = BenchmarkStatus.idle;
  String? _sourceName;
  int _sourceBytes = 0;
  List<BenchmarkRun> _runs = const <BenchmarkRun>[];
  String? _errorMessage;

  /// Current controller status.
  BenchmarkStatus get status => _status;

  /// Whether a benchmark is currently compressing.
  bool get isRunning => _status == BenchmarkStatus.running;

  /// Source file name of the last benchmark.
  String? get sourceName => _sourceName;

  /// Source size in bytes of the last benchmark.
  int get sourceBytes => _sourceBytes;

  /// Measured runs, newest quality first order kept from [qualities].
  List<BenchmarkRun> get runs => _runs;

  /// User-safe error text for the last failed run.
  String? get errorMessage => _errorMessage;

  /// The fastest measured run, or null when no run has completed.
  BenchmarkRun? get fastestRun => _runs.isEmpty
      ? null
      : _runs.reduce(
          (BenchmarkRun a, BenchmarkRun b) => a.elapsed <= b.elapsed ? a : b,
        );

  /// The run with the best compression ratio, or null when no run completed.
  BenchmarkRun? get bestRatio => _runs.isEmpty
      ? null
      : _runs.reduce(
          (BenchmarkRun a, BenchmarkRun b) => a.ratio >= b.ratio ? a : b,
        );

  /// Total bytes saved across all runs.
  int get totalSaved =>
      _runs.fold(0, (int sum, BenchmarkRun run) => sum + run.savedBytes);

  /// Picks one photo and benchmarks it at every configured quality.
  Future<void> run() async {
    if (isRunning) return;
    _status = BenchmarkStatus.running;
    _errorMessage = null;
    notifyListeners();
    final String? path;
    try {
      path = await _pickerGateway.pickImagePath();
    } catch (error) {
      _fail(error);
      return;
    }
    if (path == null) {
      _status = BenchmarkStatus.idle;
      notifyListeners();
      return;
    }
    final List<String> outputs = <String>[];
    try {
      final PhotoAsset asset = await _compressionGateway.inspect(path);
      // A new benchmark replaces the previous results so stale runs are never
      // shown next to a fresh error or progress state.
      _runs = const <BenchmarkRun>[];
      final List<BenchmarkRun> next = <BenchmarkRun>[];
      for (final int quality in _qualities) {
        final ({CompressedAsset value, BenchmarkMeasurement measurement})
        measured = await _timer.measure(
          'benchmark-quality-$quality',
          () => _compressionGateway.compress(asset, quality: quality),
        );
        next.add(
          BenchmarkRun(
            quality: quality,
            elapsed: measured.measurement.elapsed,
            inputBytes: asset.bytes,
            outputBytes: measured.value.bytes,
          ),
        );
        outputs.add(measured.value.filePath);
      }
      _sourceName = p.basename(path);
      _sourceBytes = asset.bytes;
      _runs = next;
      _status = BenchmarkStatus.done;
      notifyListeners();
    } catch (error) {
      _fail(error);
    } finally {
      for (final String output in outputs) {
        try {
          await _compressionGateway.deleteTemporaryOutput(output);
        } on Object {
          // Temporary cleanup is best effort and must not mask a result.
        }
      }
    }
  }

  void _fail(Object error) {
    _status = BenchmarkStatus.error;
    _errorMessage = _friendlyError(error);
    notifyListeners();
  }

  String _friendlyError(Object error) {
    if (error is UnsupportedError) {
      return error.message?.toString() ??
          'This action is not supported on this device.';
    }
    final String message = error.toString();
    return message.startsWith('Exception:')
        ? message.substring('Exception:'.length).trim()
        : message;
  }
}

/// Benchmarks the real compressor on one photo and compares quality settings.
class BenchmarkScreen extends StatefulWidget {
  /// Creates the benchmark screen.
  const BenchmarkScreen({
    required this.pickerGateway,
    required this.compressionGateway,
    required this.timer,
    super.key,
  });

  /// Selects a user-owned photo.
  final ImagePickerGateway pickerGateway;

  /// Real compression engine used by the workflow.
  final ImageCompressionGateway compressionGateway;

  /// Local timer used to measure each run.
  final BenchmarkTimer timer;

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  late final BenchmarkController _controller = BenchmarkController(
    pickerGateway: widget.pickerGateway,
    compressionGateway: widget.compressionGateway,
    timer: widget.timer,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.benchmark)),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? child) => ListView(
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
                    _BenchmarkHero(),
                    const SizedBox(height: AppSpacing.lg),
                    _RunCard(controller: _controller, onRun: _controller.run),
                    if (_controller.status ==
                        BenchmarkStatus.error) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      AppErrorCard(
                        title: l10n.genericError,
                        message: _controller.errorMessage ?? l10n.genericError,
                        action: AppButton(
                          label: l10n.tryAgain,
                          icon: Icons.refresh_rounded,
                          onPressed: _controller.run,
                        ),
                      ),
                    ],
                    if (_controller.runs.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xl),
                      AppSectionHeader(title: l10n.benchmarkResults),
                      const SizedBox(height: AppSpacing.md),
                      _ResultsGrid(controller: _controller),
                      const SizedBox(height: AppSpacing.xl),
                      AppSectionHeader(title: l10n.benchmarkComparison),
                      const SizedBox(height: AppSpacing.md),
                      _ComparisonCard(controller: _controller),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenchmarkHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Icon(Icons.speed_rounded, color: colors.primary, size: 26),
        const SizedBox(width: AppDimensions.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.benchmark,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.3,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                l10n.benchmarkSubtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RunCard extends StatelessWidget {
  const _RunCard({required this.controller, required this.onRun});

  final BenchmarkController controller;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppSurface(
      padding: AppSpacing.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            controller.isRunning
                ? l10n.benchmarkRunning
                : controller.runs.isEmpty
                ? l10n.benchmarkEmptyTitle
                : controller.sourceName ?? l10n.benchmark,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (!controller.isRunning) ...<Widget>[
            const SizedBox(height: AppDimensions.spacingXs),
            Text(
              controller.runs.isEmpty
                  ? l10n.benchmarkEmptyMessage
                  : FileSizeFormatter.format(controller.sourceBytes),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          if (controller.isRunning) ...<Widget>[
            const SizedBox(height: AppDimensions.spacingMd),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: AppDimensions.spacingLg),
          AppButton(
            label: controller.runs.isEmpty
                ? l10n.benchmarkChooseImage
                : l10n.benchmarkRun,
            icon: Icons.add_photo_alternate_rounded,
            onPressed: controller.isRunning ? null : onRun,
            loading: controller.isRunning,
            loadingLabel: l10n.benchmarkRunning,
            expand: true,
          ),
        ],
      ),
    );
  }
}

class _ResultsGrid extends StatelessWidget {
  const _ResultsGrid({required this.controller});

  final BenchmarkController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final BenchmarkRun? fastest = controller.fastestRun;
    final BenchmarkRun? best = controller.bestRatio;
    return AppResponsiveGrid(
      phoneColumns: 2,
      tabletColumns: 4,
      children: <Widget>[
        _BenchmarkStat(
          label: l10n.benchmarkFastest,
          value: fastest == null
              ? l10n.notAvailable
              : _formatDuration(fastest.elapsed),
          icon: Icons.bolt_rounded,
        ),
        _BenchmarkStat(
          label: l10n.benchmarkBestRatio,
          value: best == null
              ? l10n.notAvailable
              : '${best.ratio.toStringAsFixed(1)}×',
          icon: Icons.compress_rounded,
        ),
        _BenchmarkStat(
          label: l10n.benchmarkTotalSaved,
          value: FileSizeFormatter.format(controller.totalSaved),
          icon: Icons.savings_outlined,
        ),
        _BenchmarkStat(
          label: l10n.benchmarkSpeed,
          value: fastest == null
              ? l10n.notAvailable
              : _formatSpeed(fastest.bytesPerSecond),
          icon: Icons.speed_rounded,
        ),
      ],
    );
  }

  String _formatDuration(Duration value) => value.inMilliseconds < 1000
      ? '${value.inMilliseconds} ms'
      : '${(value.inMilliseconds / 1000).toStringAsFixed(1)} s';

  String _formatSpeed(double bytesPerSecond) =>
      '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(2)} MB/s';
}

class _BenchmarkStat extends StatelessWidget {
  const _BenchmarkStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => AppSurface(
    child: AppMetric(icon: icon, label: label, value: value),
  );
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.controller});

  final BenchmarkController controller;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (
            int index = 0;
            index < controller.runs.length;
            index++
          ) ...<Widget>[
            _ComparisonRow(
              run: controller.runs[index],
              highlight: controller.runs[index] == controller.bestRatio,
            ),
            if (index != controller.runs.length - 1)
              Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: .5),
              ),
          ],
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.run, required this.highlight});

  final BenchmarkRun run;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color contentColor = highlight ? colors.primary : colors.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: highlight
                  ? colors.primary.withValues(alpha: .12)
                  : colors.surfaceContainerHighest.withValues(alpha: .6),
              borderRadius: AppRadii.medium,
              border: highlight
                  ? Border.all(color: colors.primary.withValues(alpha: .3))
                  : null,
            ),
            child: Text(
              l10n.settingsPercentValue(run.quality),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: highlight ? colors.primary : colors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${FileSizeFormatter.format(run.inputBytes)} → '
                  '${FileSizeFormatter.format(run.outputBytes)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: contentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.benchmarkTime} ${_duration(run.elapsed)} · '
                  '${l10n.historySaved} ${FileSizeFormatter.format(run.savedBytes)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: highlight
                  ? colors.primary.withValues(alpha: .12)
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${run.ratio.toStringAsFixed(1)}×',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: highlight ? colors.primary : colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _duration(Duration value) => value.inMilliseconds < 1000
      ? '${value.inMilliseconds} ms'
      : '${(value.inMilliseconds / 1000).toStringAsFixed(1)} s';
}
