import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import '../../../../../../core/errors/app_error.dart';
import '../../../../../../core/errors/error_code.dart';
import '../../../../../../core/errors/error_mapper.dart';
import '../../../../../../core/errors/result_error_adapter.dart';
import '../../../../../../core/models/result.dart';
import '../interfaces/file_management_interfaces.dart';
import '../models/file_management_models.dart';

/// Image picker adapter using user-mediated platform selection.
final class PlatformImagePickerService implements ImagePickerService {
  /// Creates a picker and opts into Android Photo Picker where available.
  PlatformImagePickerService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker() {
    final ImagePickerPlatform implementation = ImagePickerPlatform.instance;
    if (implementation is ImagePickerAndroid) {
      implementation.useAndroidPhotoPicker = true;
    }
  }

  final ImagePicker _picker;

  @override
  Future<Result<List<SelectedFile>>> pick(ImageSelectionRequest request) async {
    try {
      if (request.source == ImageSelectionSource.camera && request.multiple) {
        return const Result<List<SelectedFile>>.failure(
          AppError(
            code: ErrorCode.invalidArgument,
            message: 'Camera selection supports one image at a time.',
            isRecoverable: false,
          ),
        );
      }
      if (request.source == ImageSelectionSource.camera) {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: request.imageQuality,
          maxWidth: request.maxWidth,
          maxHeight: request.maxHeight,
        );
        return Result<List<SelectedFile>>.success(
          image == null
              ? const <SelectedFile>[]
              : <SelectedFile>[_selected(image)],
        );
      }
      if (request.multiple) {
        final List<XFile> images = await _picker.pickMultiImage(
          imageQuality: request.imageQuality,
          maxWidth: request.maxWidth,
          maxHeight: request.maxHeight,
        );
        return Result<List<SelectedFile>>.success(
          images.map(_selected).toList(growable: false),
        );
      }
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: request.imageQuality,
        maxWidth: request.maxWidth,
        maxHeight: request.maxHeight,
      );
      return Result<List<SelectedFile>>.success(
        image == null
            ? const <SelectedFile>[]
            : <SelectedFile>[_selected(image)],
      );
    } catch (error, stackTrace) {
      final exception = ErrorMapper.map(error, stackTrace);
      return Result<List<SelectedFile>>.failure(
        ResultErrorAdapter.fromException(exception),
      );
    }
  }

  @override
  Future<Result<List<SelectedFile>>> recoverLostSelection() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) {
        return const Result<List<SelectedFile>>.success(<SelectedFile>[]);
      }
      if (response.files case final List<XFile> files when files.isNotEmpty) {
        return Result<List<SelectedFile>>.success(
          files.map(_selected).toList(growable: false),
        );
      }
      if (response.exception case final Exception exception) {
        return Result<List<SelectedFile>>.failure(
          ResultErrorAdapter.fromException(ErrorMapper.map(exception)),
        );
      }
      return const Result<List<SelectedFile>>.success(<SelectedFile>[]);
    } catch (error, stackTrace) {
      final exception = ErrorMapper.map(error, stackTrace);
      return Result<List<SelectedFile>>.failure(
        ResultErrorAdapter.fromException(exception),
      );
    }
  }

  SelectedFile _selected(XFile file) =>
      SelectedFile(path: file.path, name: file.name);
}
