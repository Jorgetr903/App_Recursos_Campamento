import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/recurso_model.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/resource_screen.dart';
import '../main.dart';

class ActividadesScreen extends StatefulWidget {
  const ActividadesScreen({super.key});

  @override
  State<ActividadesScreen> createState() => _ActividadesScreenState();
}

class _ActividadesScreenState extends State<ActividadesScreen> {
  int? selectedAnio;
  String? selectedMomento;
  String searchQuery = "";
  List<Recurso> recursos = [];
  List<int> availableYears = [];
  bool loading = true;

  int currentPage = 1;
  bool hasMore = true;
  int _requestId = 0;
  final ScrollController _scrollController = ScrollController();

  final momentos = ["Mañana", "Tarde", "Velada", "Olimpiada"];

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
      final years = await ApiService.getYears();
      final data = await ApiService.getRecursos(
        tipo: "actividad",
        anio: selectedAnio,
        momento: selectedMomento,
        q: searchQuery.isNotEmpty ? searchQuery : null,
        page: currentPage,
        limit: 50,
      );

      if (!mounted || requestId != _requestId) return;

      setState(() {
        availableYears = years;
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
        tipo: "actividad",
        anio: selectedAnio,
        momento: selectedMomento,
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
          title: const Text("Actividades"),
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
                hintText: "Buscar actividades...",
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
                    hint: const Text("Tipo"),
                    value: selectedMomento,
                    items: momentos
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => selectedMomento = v);
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
