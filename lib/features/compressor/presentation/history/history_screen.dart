import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/models/result.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/services/file_management/interfaces/file_management_interfaces.dart';
import '../../data/services/file_management/models/file_management_models.dart';
import '../../domain/entities/application_entities.dart';
import '../design_system/design_system.dart';
import '../history_insights_controller.dart';
import '../history_insights_screen.dart';
import 'history_entry_mapper.dart';

/// Loads persisted compression history and wires the [HistoryInsightsScreen]
/// to real storage operations (delete, undo-restore) and navigation.
///
/// The screen controller is rebuilt after each load so every visit reflects
/// the latest sessions recorded by the compression workflow.
class HistoryScreen extends StatefulWidget {
  /// Creates the history destination.
  const HistoryScreen({
    required this.history,
    this.initialTab = 0,
    this.onOpenCompression,
    super.key,
  });

  /// App-owned persistent history storage.
  final HistoryStorage history;

  /// Which tab (history or insights) should be shown first.
  final int initialTab;

  /// Navigates to the compression workflow, used by empty states.
  final VoidCallback? onOpenCompression;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  bool _failed = false;
  Map<String, CompressionHistoryRecord>? _recordsById;
  HistoryInsightsController? _controller;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final Result<List<CompressionHistoryRecord>> result = await widget.history
        .readAll();
    if (!mounted) return;
    result.fold(
      onSuccess: (List<CompressionHistoryRecord> records) {
        final Map<String, CompressionHistoryRecord> byId =
            <String, CompressionHistoryRecord>{
              for (final CompressionHistoryRecord record in records)
                record.id: record,
            };
        // Mapping records to entries and aggregating insights is pure CPU
        // work that would otherwise block the UI isolate right when the route
        // transition is animating; run it on a background isolate instead.
        unawaited(_applyRecords(records, byId));
      },
      onFailure: (AppError _) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      },
    );
  }

  /// Maps and aggregates loaded records off the UI isolate, then swaps the
  /// loaded state in. Records, entries, and insights are plain sendable data.
  Future<void> _applyRecords(
    List<CompressionHistoryRecord> records,
    Map<String, CompressionHistoryRecord> byId,
  ) async {
    // With no records there is nothing to map, so skip the isolate
    // round-trip entirely; real data is transformed on a background isolate.
    final (
      List<HistoryEntry> entries,
      HistoryInsights insights,
    ) = records.isEmpty
        ? (
            const <HistoryEntry>[],
            calculateHistoryInsights(const <HistoryEntry>[]),
          )
        : await Isolate.run(() {
            final List<HistoryEntry> mapped = records
                .map(historyEntryFromRecord)
                .toList(growable: false);
            return (mapped, calculateHistoryInsights(mapped));
          });
    if (!mounted) return;
    setState(() {
      _recordsById = byId;
      _controller = HistoryInsightsController(
        entries: entries,
        insights: insights,
        onDelete: _deleteEntry,
        onRestore: _restoreEntry,
        onShare: _shareEntry,
        onCompressAgain: (HistoryEntry _) async {
          widget.onOpenCompression?.call();
        },
      );
      _loading = false;
    });
  }

  Future<void> _deleteEntry(HistoryEntry entry) async {
    final Result<void> result = await widget.history.delete(entry.id);
    if (result case Failure<void>(error: final AppError error)) {
      throw StateError(error.message);
    }
  }

  Future<void> _restoreEntry(HistoryEntry entry) async {
    final CompressionHistoryRecord? record = _recordsById?[entry.id];
    if (record == null) {
      throw StateError('History record for ${entry.id} is unavailable.');
    }
    final Result<void> result = await widget.history.save(record);
    if (result case Failure<void>(error: final AppError error)) {
      throw StateError(error.message);
    }
  }

  /// Generated-file sharing is a reserved integration, so the control gives
  /// honest feedback instead of silently doing nothing.
  Future<void> _shareEntry(HistoryEntry entry) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).historyShareReserved),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).history)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_failed || _controller == null) {
      final AppLocalizations l10n = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(l10n.history)),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AppErrorCard(
              title: l10n.genericError,
              message: l10n.historyLoadFailed,
              action: AppButton(
                label: l10n.tryAgain,
                icon: Icons.refresh_rounded,
                onPressed: _load,
              ),
            ),
          ),
        ),
      );
    }
    return HistoryInsightsScreen(
      controller: _controller!,
      initialTab: widget.initialTab,
      onOpenCompression: widget.onOpenCompression,
    );
  }
}
