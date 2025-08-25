import 'package:flutter/material.dart';
import '../models/recurso_model.dart';
import '../screens/detalle_recurso_screen.dart';

class RecursoCard extends StatelessWidget {
  final Recurso recurso;

  const RecursoCard({required this.recurso, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(recurso.titulo, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(recurso.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Icon(Icons.arrow_forward, color: Colors.blueAccent),
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => DetalleRecursoScreen(recurso: recurso),
              transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
            ),
          );
        },
      ),
    );
  }
}
