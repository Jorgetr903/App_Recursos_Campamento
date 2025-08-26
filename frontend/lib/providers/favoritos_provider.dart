import 'package:flutter/material.dart';
import '../models/recurso_model.dart';

class FavoritosProvider with ChangeNotifier {
  final List<Recurso> _favoritos = [];

  List<Recurso> get favoritos => List.unmodifiable(_favoritos);

  bool isFavorito(Recurso recurso) => _favoritos.any((r) => r.id == recurso.id);

  void toggleFavorito(Recurso recurso) {
    if (isFavorito(recurso)) {
      _favoritos.removeWhere((r) => r.id == recurso.id);
    } else {
      _favoritos.add(recurso);
    }
    notifyListeners();
  }
}
