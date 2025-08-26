import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/recurso_model.dart';

class ApiService {
  static const String baseUrl = "https://recursos-monitores.onrender.com/api";

  static Future<List<Recurso>> getRecursos({
    String? tipo,
    String? categoria,
    int? page,
    int? limit,
    int? anio,
    String? momento,
    String? tema,
    String? grupo,
  }) async {
    try {
      String url = "$baseUrl?";
      if (page != null) url += "page=$page&";
      if (limit != null) url += "limit=$limit&";
      if (tipo != null) url += "tipo=$tipo&";
      if (categoria != null) url += "categoria=$categoria&";
      if (anio != null) url += "anio=$anio&";
      if (momento != null) url += "momento=$momento&";
      if (tema != null) url += "tema=$tema&";
      if (grupo != null) url += "grupo=$grupo&";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Recurso.fromJson(json)).toList();
      } else {
        throw Exception("Error al obtener recursos del servidor");
      }
    } catch (e) {
      throw Exception("Error inesperado: $e");
    }
  }

  static Future<Recurso> getRecursoById(String id) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/recursos/$id"));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Recurso.fromJson(data);
      } else {
        throw Exception("Error al obtener recurso $id");
      }
    } on SocketException {
      throw Exception("No hay conexión al servidor");
    } catch (e) {
      throw Exception("Error inesperado: $e");
    }
  }

}
