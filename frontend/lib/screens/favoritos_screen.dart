import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favoritos_provider.dart';
import '../widgets/resource_screen.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritosProvider = context.watch<FavoritosProvider>();
    final recursosFavoritos = favoritosProvider.favoritos;

    return Scaffold(
      appBar: AppBar(title: const Text("Favoritos")),
      body: recursosFavoritos.isEmpty
          ? const Center(child: Text("No hay favoritos"))
          : ResourceScreen(recursos: recursosFavoritos),
    );
  }
}
