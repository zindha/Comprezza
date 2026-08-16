import 'package:share_plus/share_plus.dart';

import '../../../../../core/errors/app_error.dart';
import '../../../../../core/errors/error_code.dart';
import '../../../../../core/models/result.dart';
import '../../../domain/share_export/share_export_interfaces.dart';
import '../../../domain/share_export/share_export_models.dart';

/// Dispatches local files through the operating-system share sheet.
///
/// `share_plus` owns Android content-URI/FileProvider handling. This adapter
/// never sends network requests and never deletes the files after dispatch;
/// the managed temporary cleanup policy owns their lifetime.
final class SharePlusDispatcher implements ShareDispatcher {
  const SharePlusDispatcher();

  @override
  Future<Result<ShareDispatchStatus>> dispatch(
    SharePayloadBundle payload,
  ) async {
    if (payload.files.isEmpty) {
      return const Result<ShareDispatchStatus>.failure(
        AppError(
          code: ErrorCode.invalidArgument,
          message: 'There are no files to share.',
          isRecoverable: false,
        ),
      );
    }
    try {
      final ShareResult result = await SharePlus.instance.share(
        ShareParams(
          files: payload.files
              .map(
                (SharePayloadFile file) =>
                    XFile(file.path, name: file.name, mimeType: file.mimeType),
              )
              .toList(growable: false),
          subject: payload.subject,
          text: payload.message,
        ),
      );
      return Result<ShareDispatchStatus>.success(switch (result.status) {
        ShareResultStatus.success => ShareDispatchStatus.shared,
        ShareResultStatus.dismissed => ShareDispatchStatus.dismissed,
        ShareResultStatus.unavailable => ShareDispatchStatus.unavailable,
      });
    } catch (error) {
      return Result<ShareDispatchStatus>.failure(
        AppError(
          code: ErrorCode.unavailable,
          message: 'The system share sheet is unavailable.',
          cause: error,
        ),
      );
    }
  }
}
