import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/constants/app_config.dart';

/// CloudinaryService - Subida de imágenes a Cloudinary
/// Usa signed uploads con API Key + API Secret (como en tiendaOnline/Astro)
class CloudinaryService {
  /// Sube una imagen a Cloudinary usando signed upload
  /// Replica el enfoque de tiendaOnline: genera firma con api_secret
  Future<String?> uploadImage(
    File file, {
    String folder = 'fashionmarket/products',
  }) async {
    try {
      final cloudName = AppConfig.cloudinaryCloudName;
      final apiKey = AppConfig.cloudinaryApiKey;
      final apiSecret = AppConfig.cloudinaryApiSecret;

      if (cloudName.isEmpty || apiKey.isEmpty || apiSecret.isEmpty) {
        print('Error: Cloudinary credentials not configured in .env');
        return null;
      }

      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

      // Generar firma (como en tiendaOnline/src/pages/api/cloudinary-signature.ts)
      final paramsToSign = 'folder=$folder&timestamp=$timestamp$apiSecret';
      final signature = sha1.convert(utf8.encode(paramsToSign)).toString();

      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      final request = http.MultipartRequest('POST', url);
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;
      request.fields['folder'] = folder;

      // Determinar el tipo MIME
      final extension = file.path.split('.').last.toLowerCase();
      final mimeType = _getMimeType(extension);

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', mimeType),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        return jsonResponse['secure_url'] as String?;
      } else {
        print('Error uploading to Cloudinary: $responseBody');
        return null;
      }
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      return null;
    }
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'webp':
        return 'webp';
      default:
        return 'jpeg';
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

  /// Obtiene la URL optimizada de una imagen
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
