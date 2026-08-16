import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import '../domain/gateways/compressor_gateways.dart';

/// Selects user-owned images through the platform photo picker.
class PhotoPickerService implements ImagePickerGateway {
  /// Creates a picker service.
  PhotoPickerService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker() {
    final ImagePickerPlatform implementation = ImagePickerPlatform.instance;
    if (implementation is ImagePickerAndroid) {
      implementation.useAndroidPhotoPicker = true;
    }
  }

  final ImagePicker _picker;

  /// Opens the gallery and returns one selected image, if any.
  @override
  Future<String?> pickImagePath() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    return image?.path;
  }

  /// Captures a new image with the system camera, if one is available.
  @override
  Future<String?> pickCameraImagePath() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    return image?.path;
  }

  /// Recovers a result if Android destroyed the activity during picking.
  @override
  Future<String?> recoverLostImagePath() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty) return null;
    if (response.files case final List<XFile> files when files.isNotEmpty) {
      return files.first.path;
    }
    if (response.exception case final Exception exception) {
      throw exception;
    }
    return null;
  }
}
