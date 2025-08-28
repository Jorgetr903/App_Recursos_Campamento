import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favoritos_provider.dart';
import '../models/recurso_model.dart';
import '../widgets/resource_screen.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritosProvider = context.watch<FavoritosProvider>();
    final favoritosMap = favoritosProvider.all;

    // Si quieres, puedes cargar recursos desde tu API y filtrar por favoritos
    // Aquí asumimos que ya tienes todos los recursos cargados
    final favoritosActivos = favoritosMap.entries
        .where((e) => e.value == true)
        .map((e) => Recurso(
              id: e.key,
              titulo: "",       // puedes rellenar desde API si lo necesitas
              tipo: "",
              archivoUrl: "",
              fecha: DateTime.now(),
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Favoritos")),
      body: favoritosActivos.isEmpty
          ? const Center(child: Text("No hay favoritos"))
          : ResourceScreen(recursos: favoritosActivos),
    );
  }
}
