import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:io';
import '../core/constants/app_config.dart';

class CloudinaryService {
  late final CloudinaryPublic _cloudinary;

  CloudinaryService() {
    _cloudinary = CloudinaryPublic(
      AppConfig.cloudinaryCloudName,
      'fashionmarket', // Upload preset name
      cache: false,
    );
  }

  /// Sube una imagen a Cloudinary
  /// [file] - Archivo de imagen a subir
  /// [folder] - Carpeta en Cloudinary (por defecto: fashionmarket/products)
  Future<String?> uploadImage(
    File file, {
    String folder = 'fashionmarket/products',
  }) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      return null;
    }
  }

  /// Sube múltiples imágenes a Cloudinary
  Future<List<String>> uploadMultipleImages(
    List<File> files, {
    String folder = 'fashionmarket/products',
  }) async {
    final urls = <String>[];

    for (final file in files) {
      final url = await uploadImage(file, folder: folder);
      if (url != null) {
        urls.add(url);
      }
    }

    return urls;
  }

  /// Elimina una imagen de Cloudinary
  /// Nota: cloudinary_public no soporta eliminación directa
  /// Se requiere API Admin para eliminar imágenes
  /// [publicId] - ID público de la imagen en Cloudinary
  Future<bool> deleteImage(String publicId) async {
    // cloudinary_public no tiene método deleteFile
    // La eliminación debe hacerse vía Admin API o desde el dashboard
    print('Nota: La eliminación de imágenes requiere Cloudinary Admin API');
    return false;
  }

  /// Obtiene la URL optimizada de una imagen
  /// [url] - URL original de la imagen
  /// [width] - Ancho deseado
  /// [height] - Alto deseado
  /// [quality] - Calidad (0-100)
  static String getOptimizedUrl(
    String url, {
    int? width,
    int? height,
    int quality = 80,
  }) {
    if (!url.contains('cloudinary.com')) return url;

    final parts = url.split('/upload/');
    if (parts.length != 2) return url;

    final transforms = <String>[];
    if (width != null) transforms.add('w_$width');
    if (height != null) transforms.add('h_$height');
    transforms.add('q_$quality');
    transforms.add('f_auto');

    return '${parts[0]}/upload/${transforms.join(',')}/${parts[1]}';
  }
}
