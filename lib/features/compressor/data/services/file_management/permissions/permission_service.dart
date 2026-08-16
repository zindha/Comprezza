import 'dart:io';

import '../../../../../../core/errors/error_mapper.dart';
import '../../../../../../core/errors/result_error_adapter.dart';
import '../../../../../../core/models/result.dart';
import '../interfaces/file_management_interfaces.dart';

/// Enforces user-mediated access without requesting legacy storage permissions.
final class ScopedStoragePermissionService implements PermissionService {
  /// Creates a permission policy service.
  const ScopedStoragePermissionService();

  @override
  Future<Result<bool>> canAccessSelectedFile(String path) async {
    try {
      return Result<bool>.success(await File(path).exists());
    } catch (error, stackTrace) {
      final exception = ErrorMapper.map(error, stackTrace);
      return Result<bool>.failure(ResultErrorAdapter.fromException(exception));
    }
  }

  @override
  Future<Result<bool>> requestManagedAccess() async {
    // The system picker grants per-selection access; this service requests no
    // broad permission and therefore reports capability rather than a grant.
    return const Result<bool>.success(false);
  }
}
