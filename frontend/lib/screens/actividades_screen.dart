import 'package:flutter/material.dart';
import '../models/recurso_model.dart';
import '../services/api_service.dart';
import '../widgets/recurso_card.dart';

class ActividadesScreen extends StatefulWidget {
  const ActividadesScreen({super.key});
  @override
  _ActividadesScreenState createState() => _ActividadesScreenState();
}

class _ActividadesScreenState extends State<ActividadesScreen> {
  List<Recurso> recursos = [];
  bool loading = true;
  bool loadingMore = false;
  int page = 1;
  final int limit = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchRecursos();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 && !loadingMore) {
        fetchMore();
      }
    });
  }

  Future<void> fetchRecursos() async {
    setState(() => loading = true);
    try {
      final data = await ApiService.getRecursos(tipo: "actividad", page: 1, limit: limit);
      setState(() {
        recursos = data;
        page = 2;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar recursos: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> fetchMore() async {
    setState(() => loadingMore = true);
    try {
      final data = await ApiService.getRecursos(tipo: "actividad", page: page, limit: limit);
      setState(() {
        recursos.addAll(data);
        page++;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar más recursos: $e")),
      );
    } finally {
      setState(() => loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Actividades")),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchRecursos,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: recursos.length + (loadingMore ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i < recursos.length) return RecursoCard(recurso: recursos[i]);
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
    );
  }
}
