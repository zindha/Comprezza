import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

class AppProgressLinear extends StatelessWidget {
  const AppProgressLinear({this.value, this.label, super.key});
  final double? value;
  final String? label;
  @override
  Widget build(BuildContext context) {
    final double? safeValue = value?.clamp(0, 1);
    return Semantics(
      label: label ?? 'Progress',
      value: safeValue == null
          ? 'In progress'
          : '${(safeValue * 100).round()}%',
      child: LinearProgressIndicator(
        value: safeValue,
        minHeight: AppSpacing.xs,
        borderRadius: AppRadii.pillRadius,
      ),
    );
  }
}

class AppQueueProgress extends StatelessWidget {
  const AppQueueProgress({
    required this.completed,
    required this.total,
    this.queuePosition = 0,
    this.label = 'Queue progress',
    super.key,
  });
  final int completed;
  final int total;
  final int queuePosition;
  final String label;
  @override
  Widget build(BuildContext context) {
    final int safeTotal = total < 0 ? 0 : total;
    final int safeCompleted = completed.clamp(0, safeTotal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppProgressLinear(
          value: safeTotal == 0 ? 0 : (safeCompleted / safeTotal).clamp(0, 1),
          label: label,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$safeCompleted of $safeTotal complete${queuePosition > 0 ? ' · #$queuePosition in queue' : ''}',
          style: AppTypography.caption(context),
        ),
      ],
    );
  }
}
