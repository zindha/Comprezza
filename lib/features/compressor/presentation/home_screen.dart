import 'package:flutter/material.dart';

import 'compression_workflow_screen.dart';
import 'compressor_controller.dart';

/// Compatibility entry point for the transitional compressor adapter.
///
/// The adapter and its dependency seam remain unchanged; Phase 7 owns the
/// rendered workflow in [CompressionWorkflowScreen].
class HomeScreen extends StatelessWidget {
  /// Creates the compressor workflow entry point.
  const HomeScreen({
    required this.controller,
    required this.isDarkMode,
    required this.onThemeToggle,
    super.key,
  });

  /// Feature state controller.
  final CompressorController controller;

  /// Whether dark mode is currently active.
  final bool isDarkMode;

  /// Toggles the application theme.
  final VoidCallback onThemeToggle;

  @override
  Widget build(BuildContext context) => CompressionWorkflowScreen(
    controller: controller,
    isDarkMode: isDarkMode,
    onThemeToggle: onThemeToggle,
  );
}
