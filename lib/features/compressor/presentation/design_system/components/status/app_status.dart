import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../buttons/app_buttons.dart';
import '../icons/app_icons.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    required this.title,
    required this.message,
    this.onRetry,
    super.key,
  });
  final String title;
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: .5),
              shape: BoxShape.circle,
              border: Border.all(color: scheme.error.withValues(alpha: .3)),
            ),
            child: AppIcons.icon(
              AppIcon.error,
              size: AppIconSizes.xl,
              color: scheme.error,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: AppTypography.headline(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: AppTypography.body(context),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: AppButton(
                label: 'Try again',
                onPressed: onRetry,
                tone: AppButtonTone.outlined,
              ),
            ),
        ],
      ),
    );
  }
}
