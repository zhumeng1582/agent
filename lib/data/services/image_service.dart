import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (image == null) return null;
    return await _saveImage(image);
  }

  Future<String?> pickFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (image == null) return null;
    return await _saveImage(image);
  }

  Future<String> _saveImage(XFile image) async {
    final dir = await getApplicationDocumentsDirectory();
    final uuid = const Uuid().v4();
    final ext = image.path.split('.').last;
    final newPath = '${dir.path}/image_$uuid.$ext';
    await File(image.path).copy(newPath);
    return newPath;
  }

  Future<void> deleteImage(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
