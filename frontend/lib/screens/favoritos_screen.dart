import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/recurso_model.dart';
import '../widgets/recurso_card.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  _FavoritosScreenState createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  late Box favoritosBox;

  @override
  void initState() {
    super.initState();
    favoritosBox = Hive.box('favoritos');
  }

  @override
  Widget build(BuildContext context) {
    List<Recurso> favoritos = favoritosBox.values.cast<Recurso>().toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Favoritos")),
      body: favoritos.isEmpty
          ? const Center(child: Text("No tienes favoritos"))
          : ListView.builder(
              itemCount: favoritos.length,
              itemBuilder: (_, i) => RecursoCard(recurso: favoritos[i]),
            ),
    );
  }
}
