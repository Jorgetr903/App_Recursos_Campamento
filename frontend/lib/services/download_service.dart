import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  static Future<String?> downloadFile(String url, String filename, Function(double)? onProgress) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = "${dir.path}/$filename";
      await Dio().download(url, path, onReceiveProgress: (rec, total) {
        if (onProgress != null) onProgress(rec / total);
      });
      return path;
    } catch (e) {
      print("Error al descargar archivo: $e");
      return null;
    }
  }
}
