class Recurso {
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


  /// URL completa para abrir el archivo
  String get fullUrl {
    return "https://recursos-monitores.onrender.com$archivoUrl";
  }

  /// Clave única para guardar en favoritos
  String get key => id;
}
