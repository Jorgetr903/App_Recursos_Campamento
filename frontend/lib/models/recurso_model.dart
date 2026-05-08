class Recurso {
  static const String _baseUrl = "https://recursos-monitores.onrender.com";

  final String id;
  final String titulo;
  final String? descripcion;
  final String tipo; // "formacion", "actividad", "dinamica"
  final String archivoUrl;
  final int? anio;
  final String? momento;
  final String? tema;
  final String? grupo;
  final DateTime fecha;

  Recurso({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.tipo,
    required this.archivoUrl,
    this.anio,
    this.momento,
    this.tema,
    this.grupo,
    required this.fecha,
  });

  factory Recurso.fromJson(Map<String, dynamic> json) {
    return Recurso(
      id: json['_id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      tipo: json['tipo'],
      archivoUrl: json['archivoUrl'],
      anio: json['anio'] != null ? int.tryParse(json['anio'].toString()) : null,
      momento: json['momento'],
      tema: json['tema'],
      grupo: json['grupo'],
      fecha: DateTime.parse(json['fecha']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'tipo': tipo,
      'archivoUrl': archivoUrl,
      'anio': anio,
      'momento': momento,
      'tema': tema,
      'grupo': grupo,
      'fecha': fecha.toIso8601String(),
    };
  }

  /// URL completa para abrir/compartir el archivo.
  ///
  /// Se reconstruye con `Uri` para que nombres con espacios se compartan como
  /// `%20` y no se corten al pegarlos en chats o navegadores.
  String get fullUrl {
    final rawUrl = archivoUrl.trim();
    final parsed = Uri.tryParse(rawUrl);

    if (parsed != null && parsed.hasScheme) {
      return parsed.replace(
        pathSegments: parsed.pathSegments.map(Uri.decodeComponent).toList(),
      ).toString();
    }

    final relativeUri = Uri.tryParse(rawUrl);
    final path = relativeUri?.path ?? rawUrl;
    final pathSegments = path
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map(Uri.decodeComponent)
        .toList();

    return Uri.parse(_baseUrl).replace(
      pathSegments: pathSegments,
      query: relativeUri?.hasQuery == true ? relativeUri!.query : null,
    ).toString();
  }

  /// URL que fuerza descarga desde el backend cuando se usa en navegador.
  String get downloadUrl {
    final uri = Uri.parse(fullUrl);
    final pathSegments = uri.pathSegments.map(Uri.decodeComponent).toList();

    if (pathSegments.isNotEmpty &&
        pathSegments.first == 'uploads' &&
        pathSegments.last != 'download') {
      return uri.replace(pathSegments: [...pathSegments, 'download']).toString();
    }

    return fullUrl;
  }

  /// Clave unica para guardar en favoritos.
  String get key => id;
}
