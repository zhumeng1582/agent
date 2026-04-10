import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  static Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestPhotoLibrary() async {
    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  static Future<bool> checkMicrophone() async {
    return await Permission.microphone.isGranted;
  }

  static Future<bool> checkCamera() async {
    return await Permission.camera.isGranted;
  }

  static Future<bool> checkPhotoLibrary() async {
    final status = await Permission.photos.status;
    return status.isGranted || status.isLimited;
  }
}
