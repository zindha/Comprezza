import '../../../domain/share_export/share_export_interfaces.dart';
import '../file_management/interfaces/file_management_interfaces.dart';

/// Deletes only generated artifacts through the existing owned-path policy.
final class ManagedShareExportCleanup implements ShareExportCleanup {
  const ManagedShareExportCleanup({required this.utilities});

  final FileUtilities utilities;

  @override
  Future<void> deleteGenerated(String path) async {
    await utilities.safeDelete(path);
  }
}
