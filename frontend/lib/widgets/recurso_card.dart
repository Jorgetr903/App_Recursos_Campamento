import 'package:flutter/material.dart';
import '../models/recurso_model.dart';
import '../screens/detalle_recurso_screen.dart';

class RecursoCard extends StatelessWidget {
  final Recurso recurso;
  final Widget? trailing;

  const RecursoCard({
    super.key,
    required this.recurso,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        leading: const Icon(Icons.description),
        title: Text(recurso.titulo),
        subtitle: Text(recurso.descripcion ?? ''),
        trailing: trailing,
        onTap: () {
          // Abrir PDF, video o audio usando recurso.fullUrl
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetalleRecursoScreen(recurso: recurso),
            ),
          );
        },
      ),
    );
  }
}
