import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/recurso_model.dart';

class FavoritosProvider with ChangeNotifier {
  final Box _box = Hive.box('favoritos');
  final List<Recurso> _favoritos = [];

  FavoritosProvider() {
    _loadFromHive();
  }

  List<Recurso> get favoritos => List.unmodifiable(_favoritos);

  bool esFavorito(Recurso recurso) => _favoritos.any((r) => r.id == recurso.id);

  void toggleFavorito(Recurso recurso) {
    if (esFavorito(recurso)) {
      _favoritos.removeWhere((r) => r.id == recurso.id);
      _box.delete(recurso.id);
    } else {
      _favoritos.add(recurso);
      _box.put(recurso.id, recurso.toJson());
    }
    notifyListeners();
  }

  void _loadFromHive() {
    _favoritos.clear();
    for (var key in _box.keys) {
      final json = _box.get(key);
      if (json is Map) { // <-- importante
        _favoritos.add(Recurso.fromJson(Map<String, dynamic>.from(json)));
      }
    }
    notifyListeners();
  }
}
