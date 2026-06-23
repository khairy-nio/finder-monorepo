import 'package:image_picker/image_picker.dart';

/// Utility class for image operations
class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  static Future<XFile?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  /// Capture image from camera
  static Future<XFile?> captureFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to capture image from camera: $e');
    }
  }

  /// Show dialog to choose image source
  static Future<XFile?> pickImage({required bool fromCamera}) async {
    if (fromCamera) {
      return await captureFromCamera();
    } else {
      return await pickFromGallery();
    }
  }
}
