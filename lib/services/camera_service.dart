import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class CameraService {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> capturePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    return _saveImageToLocal(photo);
  }

  static Future<String?> pickFromGallery() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    return _saveImageToLocal(photo);
  }

  static Future<String?> _saveImageToLocal(XFile? photo) async {
    if (photo == null) return null;
    
    // On web, image_picker creates a blob URL in photo.path. We can just return it.
    if (kIsWeb) {
      return photo.path;
    }
    
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(photo.path)}';
    final String savedPath = p.join(appDir.path, fileName);
    
    await File(photo.path).copy(savedPath);
    return savedPath;
  }
}
