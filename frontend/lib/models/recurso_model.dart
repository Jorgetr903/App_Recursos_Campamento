class Recurso {
  final String id;
  final String titulo;
  final String descripcion;
  final String categoria;
  final String tipo;
  final String tipoArchivo;
  final String urlArchivo;

  Recurso({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.tipo,
    required this.tipoArchivo,
    required this.urlArchivo,
  });

  factory Recurso.fromJson(Map<String, dynamic> json) {
    return Recurso(
      id: json['_id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'] ?? '',
      categoria: json['categoria'] ?? '',
      tipo: json['tipo'],
      tipoArchivo: json['tipo_archivo'],
      urlArchivo: json['url_archivo'],
    );
  }
}
