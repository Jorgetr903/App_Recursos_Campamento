import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/recurso_model.dart';

class FavoritosProvider with ChangeNotifier {
  late Box _box;

  FavoritosProvider() {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box('favoritos');
    notifyListeners();
  }

  /// Devuelve si un recurso está marcado como favorito
  bool esFavorito(Recurso recurso) {
    return _box.get(recurso.key, defaultValue: false);
  }

  /// Cambia el estado de favorito
  void toggleFavorito(Recurso recurso) {
    final current = esFavorito(recurso);
    _box.put(recurso.key, !current);
    notifyListeners();
  }

  /// Devuelve todos los recursos que están como favoritos (solo claves)
  Map<String, bool> get all {
    return _box.toMap().cast<String, bool>();
  }
}
