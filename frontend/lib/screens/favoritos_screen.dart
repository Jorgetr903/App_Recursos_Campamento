import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favoritos_provider.dart';
import '../widgets/resource_screen.dart';
import '../main.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritos = context.watch<FavoritosProvider>().favoritos;

    return WillPopScope(
      onWillPop: () async {
        mainNavKey.currentState?.setIndex(0);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Favoritos"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              mainNavKey.currentState?.setIndex(0);
            },
          ),
        ),
        body: favoritos.isEmpty
            ? const Center(child: Text("No hay favoritos"))
            : ResourceScreen(recursos: favoritos),
      ),
    );
  }
}
