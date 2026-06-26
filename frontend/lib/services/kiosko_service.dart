import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:CSP/web_utils.dart'
    if (dart.library.io) 'package:CSP/web_utils_stub.dart' as platform;

// ══════════════════════════════════════════════════════════════════
//  MODELOS
// ══════════════════════════════════════════════════════════════════

class Gasto {
  final int dia;
  final double cantidad;

  Gasto({required this.dia, required this.cantidad});

  factory Gasto.fromJson(Map<String, dynamic> json) => Gasto(
        dia: (json['dia'] as num).toInt(),
        cantidad: (json['cantidad'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'dia': dia, 'cantidad': cantidad};
}

class Acampado {
  final String id;
  final String nombre;
  final String apellidos;
  double totalTraido;
  List<Gasto> gastos;

  Acampado({
    required this.id,
    required this.nombre,
    required this.apellidos,
    this.totalTraido = 0,
    List<Gasto>? gastos,
  }) : gastos = gastos ?? [];

  double get totalGastado => gastos.fold(0.0, (s, g) => s + g.cantidad);
  double get saldo => totalTraido - totalGastado;
  String get nombreCompleto => '$nombre $apellidos';

  factory Acampado.fromJson(Map<String, dynamic> json) => Acampado(
        id: json['_id'] ?? json['id'] ?? '',
        nombre: json['nombre'] ?? '',
        apellidos: json['apellidos'] ?? '',
        totalTraido: (json['totalTraido'] as num?)?.toDouble() ?? 0,
        gastos: (json['gastos'] as List<dynamic>?)
                ?.map((g) => Gasto.fromJson(g as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'nombre': nombre,
        'apellidos': apellidos,
        'totalTraido': totalTraido,
        'gastos': gastos.map((g) => g.toJson()).toList(),
      };
}

class CuadernoKiosko {
  final int anio;
  List<Acampado> acampados;
  DateTime? updatedAt;

  CuadernoKiosko({
    required this.anio,
    List<Acampado>? acampados,
    this.updatedAt,
  }) : acampados = acampados ?? [];

  factory CuadernoKiosko.fromJson(Map<String, dynamic> json) => CuadernoKiosko(
        anio: json['anio'] as int,
        acampados: (json['acampados'] as List<dynamic>?)
                ?.map((a) => Acampado.fromJson(a as Map<String, dynamic>))
                .toList() ??
            [],
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'anio': anio,
        'acampados': acampados.map((a) => a.toJson()).toList(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

enum ModoPDF { blanco, completo }

class KioskoLoadResult {
  final CuadernoKiosko? cuaderno;
  final bool fromCache;
  final bool notFound;
  final Object? error;

  const KioskoLoadResult({
    required this.cuaderno,
    this.fromCache = false,
    this.notFound = false,
    this.error,
  });

  bool get hasError => error != null;
}

// ══════════════════════════════════════════════════════════════════
//  SERVICIO
// ══════════════════════════════════════════════════════════════════

class KioskoService {
  static const String _baseUrl = 'https://recursos-monitores.onrender.com/api/kiosko';
  static const String _cacheKey = 'kiosko_cache';

  final http.Client _client;
  KioskoService({http.Client? client}) : _client = client ?? http.Client();

  // ─────────────────────────────────────────────
  //  Cache local
  // ─────────────────────────────────────────────

  Future<void> _saveToCache(CuadernoKiosko cuaderno) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_cacheKey}_${cuaderno.anio}',
      jsonEncode(cuaderno.toJson()),
    );
  }

  Future<CuadernoKiosko?> _loadFromCache(int anio) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('${_cacheKey}_$anio');
      if (data == null) return null;
      return CuadernoKiosko.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  //  Cola de pendientes — PÚBLICO para la UI
  // ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPendingOps(int anio) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('kiosko_pending_$anio');
      if (raw == null) return [];
      return List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> _savePendingOp(int anio, Map<String, dynamic> op) async {
    final ops = await getPendingOps(anio);
    ops.add(op);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kiosko_pending_$anio', jsonEncode(ops));
  }

  Future<void> _clearPendingOps(int anio) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('kiosko_pending_$anio');
  }

  // ─────────────────────────────────────────────
  //  Obtener cuaderno (con fallback offline)
  // ─────────────────────────────────────────────

  Future<KioskoLoadResult> getCuadernoResult(int anio) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/$anio'))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final cuaderno = CuadernoKiosko.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
        await _saveToCache(cuaderno);
        return KioskoLoadResult(cuaderno: cuaderno);
      } else if (response.statusCode == 404) {
        return const KioskoLoadResult(cuaderno: null, notFound: true);
      }
      final cache = await _loadFromCache(anio);
      return KioskoLoadResult(
        cuaderno: cache,
        fromCache: cache != null,
        error: 'HTTP ${response.statusCode}: ${response.body}',
      );
    } catch (e) {
      final cache = await _loadFromCache(anio);
      return KioskoLoadResult(
        cuaderno: cache,
        fromCache: cache != null,
        error: e,
      );
    }
  }

  Future<CuadernoKiosko?> getCuaderno(int anio) async {
    return (await getCuadernoResult(anio)).cuaderno;
  }

  // ─────────────────────────────────────────────
  //  Crear cuaderno
  // ─────────────────────────────────────────────

  Future<CuadernoKiosko> crearCuaderno(
      int anio, List<Map<String, dynamic>> acampados) async {
    final response = await _client
        .post(
          Uri.parse(_baseUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'anio': anio, 'acampados': acampados}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      final cuaderno = CuadernoKiosko.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
      await _saveToCache(cuaderno);
      return cuaderno;
    }
    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  // ─────────────────────────────────────────────
  //  Añadir acampado a cuaderno existente
  // ─────────────────────────────────────────────

  Future<CuadernoKiosko> anadirAcampado(
      int anio, String nombre, String apellidos) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/$anio/acampados'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'acampados': [
              {'nombre': nombre, 'apellidos': apellidos, 'totalTraido': 0}
            ]
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      final cuaderno = CuadernoKiosko.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
      await _saveToCache(cuaderno);
      return cuaderno;
    }
    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  // ─────────────────────────────────────────────
  //  Eliminar acampado
  // ─────────────────────────────────────────────

  Future<bool> eliminarAcampado(int anio, String acampadoId) async {
    // Actualizar cache local inmediatamente
    final cache = await _loadFromCache(anio);
    if (cache != null) {
      cache.acampados.removeWhere((a) => a.id == acampadoId);
      await _saveToCache(cache);
    }

    try {
      final response = await _client
          .delete(Uri.parse('$_baseUrl/$anio/acampados/$acampadoId'))
          .timeout(const Duration(seconds: 6));
      return response.statusCode == 200;
    } catch (_) {
      await _savePendingOp(anio, {
        'type': 'deleteAcampado',
        'acampadoId': acampadoId,
      });
      return true;
    }
  }

  // ─────────────────────────────────────────────
  //  Actualizar dinero traído
  // ─────────────────────────────────────────────

  Future<bool> actualizarDinero(
      int anio, String acampadoId, double cantidad) async {
    final cache = await _loadFromCache(anio);
    if (cache != null) {
      final idx = cache.acampados.indexWhere((a) => a.id == acampadoId);
      if (idx >= 0) cache.acampados[idx].totalTraido = cantidad;
      await _saveToCache(cache);
    }

    try {
      final response = await _client
          .patch(
            Uri.parse('$_baseUrl/$anio/acampados/$acampadoId/dinero'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'totalTraido': cantidad}),
          )
          .timeout(const Duration(seconds: 6));
      return response.statusCode == 200;
    } catch (_) {
      await _savePendingOp(anio, {
        'type': 'updateDinero',
        'acampadoId': acampadoId,
        'totalTraido': cantidad,
      });
      return true;
    }
  }

  // ─────────────────────────────────────────────
  //  Registrar gasto
  // ─────────────────────────────────────────────

  Future<bool> registrarGasto(
      int anio, String acampadoId, int dia, double cantidad) async {
    final gasto = {'dia': dia, 'cantidad': cantidad};

    final cache = await _loadFromCache(anio);
    if (cache != null) {
      final idx = cache.acampados.indexWhere((a) => a.id == acampadoId);
      if (idx >= 0) {
        cache.acampados[idx].gastos.add(Gasto.fromJson(gasto));
        await _saveToCache(cache);
      }
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/$anio/acampados/$acampadoId/gastos'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(gasto),
          )
          .timeout(const Duration(seconds: 6));
      return response.statusCode == 201;
    } catch (_) {
      await _savePendingOp(anio, {
        'type': 'addGasto',
        'acampadoId': acampadoId,
        ...gasto,
      });
      return true;
    }
  }

  // ─────────────────────────────────────────────
  //  Eliminar gasto
  // ─────────────────────────────────────────────

  Future<bool> eliminarGasto(
      int anio, String acampadoId, int gastoIndex) async {
    final cache = await _loadFromCache(anio);
    if (cache != null) {
      final idx = cache.acampados.indexWhere((a) => a.id == acampadoId);
      if (idx >= 0 && gastoIndex < cache.acampados[idx].gastos.length) {
        cache.acampados[idx].gastos.removeAt(gastoIndex);
        await _saveToCache(cache);
      }
    }

    try {
      final response = await _client
          .delete(Uri.parse(
              '$_baseUrl/$anio/acampados/$acampadoId/gastos/$gastoIndex'))
          .timeout(const Duration(seconds: 6));
      return response.statusCode == 200;
    } catch (_) {
      await _savePendingOp(anio, {
        'type': 'deleteGasto',
        'acampadoId': acampadoId,
        'index': gastoIndex,
      });
      return true;
    }
  }

  // ─────────────────────────────────────────────
  //  Exportar PDF — descarga directa en el navegador
  // ─────────────────────────────────────────────

  Future<void> exportarPDF(int anio, {ModoPDF modo = ModoPDF.completo}) async {
    final modoParam = modo == ModoPDF.blanco ? 'blanco' : 'completo';
    final url = '$_baseUrl/$anio/export/pdf?modo=$modoParam';
    final nombreArchivo = modo == ModoPDF.blanco
        ? 'Cuaderno_Kiosko_${anio}_EnBlanco.pdf'
        : 'Cuaderno_Kiosko_${anio}_Completo.pdf';

    // Usa downloadPdfUrl definida en web/index.html
    platform.downloadUrl(url, nombreArchivo);
  }

  // ─────────────────────────────────────────────
  //  Sincronizar pendientes offline
  // ─────────────────────────────────────────────

  Future<int> sincronizarPendientes(int anio) async {
    final ops = await getPendingOps(anio);
    if (ops.isEmpty) return 0;

    int sincronizadas = 0;
    for (final op in ops) {
      try {
        bool ok = false;
        switch (op['type']) {
          case 'updateDinero':
            ok = await actualizarDinero(
                anio, op['acampadoId'], (op['totalTraido'] as num).toDouble());
            break;
          case 'addGasto':
            ok = await registrarGasto(anio, op['acampadoId'],
                op['dia'] as int, (op['cantidad'] as num).toDouble());
            break;
          case 'deleteGasto':
            ok = await eliminarGasto(
                anio, op['acampadoId'], op['index'] as int);
            break;
          case 'deleteAcampado':
            ok = await eliminarAcampado(anio, op['acampadoId']);
            break;
        }
        if (ok) sincronizadas++;
      } catch (_) {
        break;
      }
    }

    if (sincronizadas == ops.length) await _clearPendingOps(anio);
    return sincronizadas;
  }
}
