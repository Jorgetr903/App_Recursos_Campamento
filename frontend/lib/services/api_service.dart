// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/recurso_model.dart';

class ApiService {
  static const String baseUrl = "https://recursos-monitores.onrender.com/api/recursos";

  static Future<List<Recurso>> getRecursos({
    String? tipo,
    String? categoria,
    int? page,
    int? limit,
    int? anio,
    String? momento,
    String? tema,
    String? grupo,
    String? q,           // <--- NUEVO
    String? sort,        // <--- NUEVO: "recent" | "oldest" | "alpha"
  }) async {
    try {
      final params = <String, String>{};
      if (tipo != null) params['tipo'] = tipo;
      if (categoria != null) params['categoria'] = categoria;
      if (anio != null) params['anio'] = anio.toString();
      if (momento != null) params['momento'] = momento;
      if (tema != null) params['tema'] = tema;
      if (grupo != null) params['grupo'] = grupo;
      if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
      if (sort != null) params['sort'] = sort;
      if (page != null) params['page'] = page.toString();
      if (limit != null) params['limit'] = limit.toString();

      final uri = Uri.parse(baseUrl).replace(queryParameters: params);
      final response = await http.get(uri);

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
      final uri = Uri.parse("$baseUrl/$id");
      final response = await http.get(uri);
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
