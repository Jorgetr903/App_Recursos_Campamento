import 'package:flutter/material.dart';

import '../services/kiosko_service.dart';

class KioskoScreen extends StatefulWidget {
  const KioskoScreen({super.key});

  @override
  State<KioskoScreen> createState() => _KioskoScreenState();
}

class _KioskoScreenState extends State<KioskoScreen> {
  final KioskoService _service = KioskoService();
  final TextEditingController _searchController = TextEditingController();

  CuadernoKiosko? _cuaderno;
  bool _loading = true;
  bool _offline = false;
  bool _syncing = false;
  bool _synced = false;
  bool _notFound = false;
  int _pendientesCount = 0;
  Object? _loadError;
  late int _anioSeleccionado;

  int get _anioActual => _anioSeleccionado;

  @override
  void initState() {
    super.initState();
    _anioSeleccionado = DateTime.now().year;
    _searchController.addListener(() => setState(() {}));
    _cargar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _synced = false;
    });

    final result = await _service.getCuadernoResult(_anioActual);
    final pendientes = await _service.getPendingOps(_anioActual);

    if (!mounted) return;
    setState(() {
      _cuaderno = result.cuaderno;
      _loading = false;
      _offline = result.hasError;
      _notFound = result.notFound;
      _loadError = result.error;
      _pendientesCount = pendientes.length;
    });
  }

  Future<void> _sincronizar() async {
    setState(() {
      _syncing = true;
      _synced = false;
    });

    final n = await _service.sincronizarPendientes(_anioActual);
    await _cargar();

    if (!mounted) return;
    setState(() {
      _syncing = false;
      _synced = n > 0 && _pendientesCount == 0;
    });

    if (_synced) {
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _synced = false);
      });
    }
  }

  Future<void> _exportarPDF(ModoPDF modo) async {
    await _service.exportarPDF(_anioActual, modo: modo);
  }

  Future<void> _mostrarMenuPDF() async {
    final modo = await showModalBottomSheet<ModoPDF>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Radio<ModoPDF>(
                  value: ModoPDF.completo,
                  groupValue: ModoPDF.completo,
                  onChanged: null,
                ),
                title: const Text('Cuaderno completo'),
                onTap: () => Navigator.pop(context, ModoPDF.completo),
              ),
              ListTile(
                leading: const Radio<ModoPDF>(
                  value: ModoPDF.blanco,
                  groupValue: ModoPDF.completo,
                  onChanged: null,
                ),
                title: const Text('Plantilla en blanco'),
                onTap: () => Navigator.pop(context, ModoPDF.blanco),
              ),
            ],
          ),
        ),
      ),
    );

    if (modo != null) await _exportarPDF(modo);
  }

  List<Acampado> get _acampadosFiltrados {
    final acampados = _cuaderno?.acampados ?? [];
    final query = _normalize(_searchController.text);
    if (query.isEmpty) return acampados;

    final terms = query.split(' ').where((term) => term.isNotEmpty);
    return acampados.where((a) {
      final fullName = _normalize(a.nombreCompleto);
      return terms.every(fullName.contains);
    }).toList();
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String _money(double value) {
    final rounded = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
    return '$rounded €';
  }

  Color _saldoColor(double saldo) {
    if (saldo <= 0) return const Color(0xFFB71C1C);
    if (saldo < 5) return Colors.red.shade700;
    if (saldo <= 10) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  Future<void> _abrirFicha(Acampado acampado) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AcampadoDetalleScreen(
          acampado: acampado,
          anio: _anioActual,
          service: _service,
        ),
      ),
    );

    if (changed == true && mounted) {
      final pendientes = await _service.getPendingOps(_anioActual);
      setState(() => _pendientesCount = pendientes.length);
    }
  }

  void _mostrarDialogoNuevoCuaderno() {
    showDialog(
      context: context,
      builder: (_) => _NuevoCuadernoDialog(
        anio: _anioActual,
        onCreado: (acampados) async {
          Navigator.pop(context);
          await _service.crearCuaderno(_anioActual, acampados);
          await _cargar();
        },
      ),
    );
  }

  Future<void> _mostrarDialogoCambiarAnio() async {
    final year = await showDialog<int>(
      context: context,
      builder: (_) => _YearDialog(initialYear: _anioActual),
    );

    if (year == null || year == _anioActual || !mounted) return;

    setState(() {
      _anioSeleccionado = year;
      _cuaderno = null;
      _notFound = false;
      _loadError = null;
      _pendientesCount = 0;
    });
    _searchController.clear();
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Kiosko $_anioActual'),
        backgroundColor: const Color(0xFF1A5FA8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Cambiar año',
            onPressed: _loading ? null : _mostrarDialogoCambiarAnio,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'PDF',
            onPressed: _mostrarMenuPDF,
          ),
          if (_pendientesCount > 0)
            IconButton(
              icon: Icon(Icons.sync, color: _offline ? Colors.orange.shade200 : Colors.white),
              tooltip: 'Sincronizar',
              onPressed: _syncing ? null : _sincronizar,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _cargar,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cuaderno == null
              ? _buildVacio()
              : _buildPanel(),
    );
  }

  Widget _buildPanel() {
    final acampados = _acampadosFiltrados;

    return Column(
      children: [
        _buildEstadoConexion(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar acampado...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Limpiar',
                      onPressed: _searchController.clear,
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: _ResumenKiosko(acampados: _cuaderno!.acampados, money: _money),
        ),
        Expanded(
          child: acampados.isEmpty
              ? const Center(child: Text('Sin resultados'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: acampados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final acampado = acampados[index];
                    return _AcampadoCard(
                      acampado: acampado,
                      money: _money,
                      saldoColor: _saldoColor(acampado.saldo),
                      onTap: () => _abrirFicha(acampado),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEstadoConexion() {
    if (_syncing) {
      return _StatusBanner(
        color: Colors.blue.shade700,
        icon: Icons.sync,
        text: 'Sincronizando...',
      );
    }

    if (_synced) {
      return _StatusBanner(
        color: Colors.green.shade700,
        icon: Icons.check_circle_outline,
        text: 'Todo sincronizado',
      );
    }

    if (_offline || _pendientesCount > 0) {
      final pendingText = _pendientesCount == 1
          ? '1 operación pendiente'
          : '$_pendientesCount operaciones pendientes';
      return _StatusBanner(
        color: Colors.orange.shade800,
        icon: Icons.wifi_off,
        text: _offline ? 'Sin conexión · $pendingText' : pendingText,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildVacio() {
    final title = _notFound ? 'No hay cuaderno para $_anioActual' : 'No se pudo cargar el cuaderno';
    final detail = _loadError == null
        ? null
        : 'La API responde, pero el navegador puede bloquear la lectura si faltan cabeceras CORS.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _notFound ? Icons.store_outlined : Icons.cloud_off_outlined,
              size: 56,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _cargar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                ),
                if (_notFound)
                  ElevatedButton.icon(
                    onPressed: _mostrarDialogoNuevoCuaderno,
                    icon: const Icon(Icons.add),
                    label: const Text('Crear cuaderno'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AcampadoDetalleScreen extends StatefulWidget {
  final Acampado acampado;
  final int anio;
  final KioskoService service;

  const AcampadoDetalleScreen({
    super.key,
    required this.acampado,
    required this.anio,
    required this.service,
  });

  @override
  State<AcampadoDetalleScreen> createState() => _AcampadoDetalleScreenState();
}

class _AcampadoDetalleScreenState extends State<AcampadoDetalleScreen> {
  bool _changed = false;

  double get _totalGastado => widget.acampado.totalGastado;
  double get _saldo => widget.acampado.saldo;

  String _money(double value) {
    final rounded = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
    return '$rounded €';
  }

  Color _saldoColor(double saldo) {
    if (saldo <= 0) return const Color(0xFFB71C1C);
    if (saldo < 5) return Colors.red.shade700;
    if (saldo <= 10) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  int _nextDia() {
    if (widget.acampado.gastos.isEmpty) return 1;
    return widget.acampado.gastos.map((g) => g.dia).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> _anadirGasto() async {
    final draft = await showDialog<_GastoDraft>(
      context: context,
      builder: (context) => _AddGastoDialog(
        acampados: [widget.acampado],
        acampadoInicial: widget.acampado,
      ),
    );

    if (draft == null) return;

    final dia = _nextDia();
    final ok = await widget.service.registrarGasto(
      widget.anio,
      widget.acampado.id,
      dia,
      draft.cantidad,
    );

    if (!ok || !mounted) return;

    setState(() {
      widget.acampado.gastos.add(Gasto(dia: dia, cantidad: draft.cantidad));
      _changed = true;
    });
  }

  Future<void> _editarDineroInicial() async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => _MoneyDialog(
        title: 'Dinero inicial',
        initialValue: widget.acampado.totalTraido,
      ),
    );

    if (result == null) return;

    final ok = await widget.service.actualizarDinero(
      widget.anio,
      widget.acampado.id,
      result,
    );

    if (!ok || !mounted) return;

    setState(() {
      widget.acampado.totalTraido = result;
      _changed = true;
    });
  }

  Future<void> _eliminarGasto(int index) async {
    final gasto = widget.acampado.gastos[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar gasto'),
        content: Text(
          '¿Seguro que quieres borrar el gasto del Día ${gasto.dia} por ${_money(gasto.cantidad)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await widget.service.eliminarGasto(widget.anio, widget.acampado.id, index);
    if (!ok || !mounted) return;

    setState(() {
      widget.acampado.gastos.removeAt(index);
      _changed = true;
    });
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(context, _changed);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final saldoColor = _saldoColor(_saldo);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(widget.acampado.nombreCompleto.trim()),
          backgroundColor: const Color(0xFF1A5FA8),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: saldoColor.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saldo', style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  Text(
                    _money(_saldo),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: saldoColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetricBox(label: 'Traído', value: _money(widget.acampado.totalTraido)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricBox(label: 'Gastado', value: _money(_totalGastado)),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'Historial',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (widget.acampado.gastos.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text('Sin gastos', style: TextStyle(color: Colors.grey.shade700)),
              )
            else
              ...List.generate(widget.acampado.gastos.length, (index) {
                final gasto = widget.acampado.gastos[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Día ${gasto.dia}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _money(gasto.cantidad),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                          tooltip: 'Borrar',
                          onPressed: () => _eliminarGasto(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editarDineroInicial,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar dinero inicial'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _anadirGasto,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir gasto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A5FA8),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _StatusBanner({
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenKiosko extends StatelessWidget {
  final List<Acampado> acampados;
  final String Function(double) money;

  const _ResumenKiosko({
    required this.acampados,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final totalTraido = acampados.fold(0.0, (sum, a) => sum + a.totalTraido);
    final totalGastado = acampados.fold(0.0, (sum, a) => sum + a.totalGastado);
    final saldo = totalTraido - totalGastado;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(child: _SummaryItem(label: 'Acampados', value: '${acampados.length}')),
          Expanded(child: _SummaryItem(label: 'Total traído', value: money(totalTraido))),
          Expanded(child: _SummaryItem(label: 'Gastado', value: money(totalGastado))),
          Expanded(child: _SummaryItem(label: 'Saldo restante', value: money(saldo))),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 10)),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _AcampadoCard extends StatelessWidget {
  final Acampado acampado;
  final String Function(double) money;
  final Color saldoColor;
  final VoidCallback onTap;

  const _AcampadoCard({
    required this.acampado,
    required this.money,
    required this.saldoColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                acampado.nombreCompleto.trim(),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(child: _InlineMoney(label: 'Traído', value: money(acampado.totalTraido))),
                  Expanded(child: _InlineMoney(label: 'Gastado', value: money(acampado.totalGastado))),
                  Expanded(
                    child: _InlineMoney(
                      label: 'Saldo',
                      value: money(acampado.saldo),
                      valueColor: saldoColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineMoney extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InlineMoney({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;

  const _MetricBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _GastoDraft {
  final Acampado acampado;
  final double cantidad;

  const _GastoDraft({required this.acampado, required this.cantidad});
}

class _AddGastoDialog extends StatefulWidget {
  final List<Acampado> acampados;
  final Acampado? acampadoInicial;

  const _AddGastoDialog({
    required this.acampados,
    this.acampadoInicial,
  });

  @override
  State<_AddGastoDialog> createState() => _AddGastoDialogState();
}

class _AddGastoDialogState extends State<_AddGastoDialog> {
  final TextEditingController _cantidadController = TextEditingController();
  Acampado? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.acampadoInicial ?? (widget.acampados.length == 1 ? widget.acampados.first : null);
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  void _guardar() {
    final cantidad = double.tryParse(_cantidadController.text.trim().replaceAll(',', '.'));
    if (_selected == null || cantidad == null || cantidad <= 0) return;

    Navigator.pop(
      context,
      _GastoDraft(acampado: _selected!, cantidad: cantidad),
    );
  }

  @override
  Widget build(BuildContext context) {
    final needsPicker = widget.acampadoInicial == null && widget.acampados.length > 1;

    return AlertDialog(
      title: const Text('Añadir gasto'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (needsPicker) ...[
              Autocomplete<Acampado>(
                displayStringForOption: (a) => a.nombreCompleto.trim(),
                optionsBuilder: (textEditingValue) {
                  final query = _normalize(textEditingValue.text);
                  if (query.isEmpty) return widget.acampados.take(8);
                  return widget.acampados.where((a) {
                    return _normalize(a.nombreCompleto).contains(query);
                  }).take(8);
                },
                onSelected: (a) => setState(() => _selected = a),
                fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Acampado',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _cantidadController,
              autofocus: !needsPicker,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                suffixText: '€',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _guardar(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A5FA8),
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _MoneyDialog extends StatefulWidget {
  final String title;
  final double initialValue;

  const _MoneyDialog({
    required this.title,
    required this.initialValue,
  });

  @override
  State<_MoneyDialog> createState() => _MoneyDialogState();
}

class _MoneyDialogState extends State<_MoneyDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue == 0 ? '' : widget.initialValue.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _guardar() {
    final value = double.tryParse(_controller.text.trim().replaceAll(',', '.'));
    if (value == null || value < 0) return;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          suffixText: '€',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _guardar(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A5FA8),
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _NuevoCuadernoDialog extends StatefulWidget {
  final int anio;
  final Future<void> Function(List<Map<String, dynamic>>) onCreado;

  const _NuevoCuadernoDialog({
    required this.anio,
    required this.onCreado,
  });

  @override
  State<_NuevoCuadernoDialog> createState() => _NuevoCuadernoDialogState();
}

class _NuevoCuadernoDialogState extends State<_NuevoCuadernoDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _creando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final lineas = _controller.text
        .trim()
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lineas.isEmpty) return;

    final acampados = lineas.map((linea) {
      final partes = linea.split(RegExp(r'\s+'));
      return {
        'nombre': partes.first,
        'apellidos': partes.length > 1 ? partes.sublist(1).join(' ') : '',
        'totalTraido': 0,
      };
    }).toList();

    setState(() => _creando = true);
    try {
      await widget.onCreado(acampados);
    } finally {
      if (mounted) setState(() => _creando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nuevo cuaderno ${widget.anio}'),
      content: TextField(
        controller: _controller,
        maxLines: 10,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Nombre Apellidos',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _creando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _creando ? null : _crear,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A5FA8),
            foregroundColor: Colors.white,
          ),
          child: _creando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Crear'),
        ),
      ],
    );
  }
}


class _YearDialog extends StatelessWidget {
  final int initialYear;
  const _YearDialog({required this.initialYear});

  @override
  Widget build(BuildContext context) {
    final years = List.generate(5, (i) => initialYear - 1 + i);
    return SimpleDialog(
      title: const Text('Seleccionar año'),
      children: years.map((y) {
        final isCurrent = y == initialYear;
        return SimpleDialogOption(
          onPressed: () => Navigator.pop(context, y),
          child: Text(
            y.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? const Color(0xFF1A5FA8) : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}