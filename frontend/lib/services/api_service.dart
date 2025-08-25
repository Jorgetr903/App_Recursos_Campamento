import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/recurso_model.dart';

class ApiService {
  static const String baseUrl = "https://recursos-monitores.onrender.com/api";

  static Future<List<Recurso>> getRecursos({
    String? tipo,
    String? categoria,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      String url = "$baseUrl?page=$page&limit=$limit";
      if (tipo != null) url += "&tipo=$tipo";
      if (categoria != null) url += "&categoria=$categoria";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Recurso.fromJson(json)).toList();
      } else {
        throw Exception("Error al obtener recursos del servidor");
      }
    } on SocketException {
      throw Exception("No hay conexión al servidor");
    } catch (e) {
      throw Exception("Error inesperado: $e");
    }
  }
}
