import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/recurso_model.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/resource_screen.dart';
import '../main.dart';

class DinamicasScreen extends StatefulWidget {
  const DinamicasScreen({super.key});

  @override
  State<DinamicasScreen> createState() => _DinamicasScreenState();
}

class _DinamicasScreenState extends State<DinamicasScreen> {
  int? selectedAnio;
  String? selectedGrupo;
  String searchQuery = "";
  List<Recurso> recursos = [];
  List<int> availableYears = [];
  bool loading = true;

  int currentPage = 1;
  bool hasMore = true;
  int _requestId = 0;
  final ScrollController _scrollController = ScrollController();

  final grupos = ["Pequeños", "Medianos", "Mayores"];

  @override
  void initState() {
    super.initState();
    fetchYearsAndRecursos();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !loading &&
          hasMore) {
        fetchMoreRecursos();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchYearsAndRecursos() async {
    final requestId = ++_requestId;

    setState(() {
      loading = true;
      currentPage = 1;
      hasMore = true;
      recursos.clear();
    });

    try {
      final years = await ApiService.getYearsDinamicas();
      final anioFiltro =
          selectedAnio ?? (years.isNotEmpty ? years.first : null);
      final data = await ApiService.getRecursos(
        tipo: "dinamica",
        anio: anioFiltro,
        grupo: selectedGrupo,
        q: searchQuery.isNotEmpty ? searchQuery : null,
        page: currentPage,
        limit: 50,
      );

      if (!mounted || requestId != _requestId) return;

      setState(() {
        availableYears = years;
        selectedAnio = anioFiltro;
        recursos = data;
        loading = false;
        hasMore = data.length == 50;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;

      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> fetchMoreRecursos() async {
    if (!hasMore) return;

    setState(() => loading = true);

    try {
      currentPage++;
      final data = await ApiService.getRecursos(
        tipo: "dinamica",
        anio: selectedAnio,
        grupo: selectedGrupo,
        q: searchQuery.isNotEmpty ? searchQuery : null,
        page: currentPage,
        limit: 50,
      );

      if (!mounted) return;

      setState(() {
        recursos.addAll(data);
        loading = false;
        hasMore = data.length == 50;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _onSearchChanged(String value) {
    if (searchQuery == value) return;

    setState(() => searchQuery = value);
    fetchYearsAndRecursos();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        mainNavKey.currentState?.setIndex(0);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Dinámicas"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              mainNavKey.currentState?.setIndex(0);
            },
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: DebouncedSearchField(
                hintText: "Buscar dinámicas...",
                onChanged: _onSearchChanged,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  DropdownButton<int>(
                    hint: const Text("Año"),
                    value: selectedAnio,
                    items: availableYears
                        .map((a) => DropdownMenuItem(
                              value: a,
                              child: Text("$a"),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => selectedAnio = v);
                      fetchYearsAndRecursos();
                    },
                  ),
                  DropdownButton<String>(
                    hint: const Text("Grupo"),
                    value: selectedGrupo,
                    items: grupos
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => selectedGrupo = v);
                      fetchYearsAndRecursos();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ResourceScreen(
                recursos: recursos,
                controller: _scrollController,
                loading: loading,
                hasMore: hasMore,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
