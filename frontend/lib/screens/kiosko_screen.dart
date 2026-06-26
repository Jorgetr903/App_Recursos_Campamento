import 'package:flutter/material.dart';
import '../services/kiosko_service.dart';

// ══════════════════════════════════════════════════════════════════
//  PANTALLA PRINCIPAL
// ══════════════════════════════════════════════════════════════════

class KioskoScreen extends StatefulWidget {
  const KioskoScreen({Key? key}) : super(key: key);

  @override
  State<KioskoScreen> createState() => _KioskoScreenState();
}

class _KioskoScreenState extends State<KioskoScreen> {
  final KioskoService _service = KioskoService();
  CuadernoKiosko? _cuaderno;
  bool _loading = true;
  bool _offline = false;
  int _pendientesCount = 0;
  bool _exportandoPDF = false;

  int get _anioActual => DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final cuaderno = await _service.getCuaderno(_anioActual);
      final pendientes = await _service.getPendingOps(_anioActual);
      setState(() {
        _cuaderno = cuaderno;
        _loading = false;
        _pendientesCount = pendientes.length;
        _offline = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  Future<void> _sincronizar() async {
    final n = await _service.sincronizarPendientes(_anioActual);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(n > 0 ? '$n operaciones sincronizadas ✓' : 'Sin conexión o nada pendiente'),
    ));
    if (n > 0) await _cargar();
  }

  // ── PDF ───────────────────────────────────────────────────────

  Future<void> _exportarPDF(ModoPDF modo) async {
    setState(() => _exportandoPDF = true);
    try {
      await _service.exportarPDF(_anioActual, modo: modo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(modo == ModoPDF.blanco ? 'PDF en blanco generado ✓' : 'PDF completo generado ✓'),
        backgroundColor: Colors.green.shade700,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al generar PDF: $e'),
        backgroundColor: Colors.red.shade700,
      ));
    } finally {
      if (mounted) setState(() => _exportandoPDF = false);
    }
  }

  void _mostrarMenuPDF() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Exportar cuaderno',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Elige el tipo de PDF:', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.print, color: Colors.blue.shade700),
              ),
              title: const Text('Cuaderno en blanco',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Plantilla vacía para imprimir antes del campamento'),
              onTap: () { Navigator.pop(context); _exportarPDF(ModoPDF.blanco); },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.picture_as_pdf, color: Colors.green.shade700),
              ),
              title: const Text('Cuaderno completo',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Con todos los gastos registrados'),
              onTap: () { Navigator.pop(context); _exportarPDF(ModoPDF.completo); },
            ),
          ],
        ),
      ),
    );
  }

  // ── Nuevo cuaderno ────────────────────────────────────────────

  void _mostrarDialogoNuevoCuaderno() {
    showDialog(
      context: context,
      builder: (_) => _NuevoCuadernoDialog(
        anio: _anioActual,
        onCreado: (acampados) async {
          Navigator.pop(context);
          try {
            await _service.crearCuaderno(_anioActual, acampados);
          } catch (_) {
            // El cuaderno puede haberse creado igualmente en el servidor.
          }
          await _cargar();
        },
      ),
    );
  }

  // ── Añadir acampado a cuaderno existente ─────────────────────

  void _mostrarDialogoAnadirAcampado() {
    showDialog(
      context: context,
      builder: (_) => _AnadirAcampadoDialog(
        onAnadido: (nombre, apellidos) async {
          Navigator.pop(context);
          try {
            await _service.anadirAcampado(_anioActual, nombre, apellidos);
            await _cargar();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$nombre $apellidos añadido ✓'),
                backgroundColor: Colors.green.shade700,
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al añadir acampado: $e'),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
      ),
    );
  }

  // ── Eliminar acampado ─────────────────────────────────────────

  void _confirmarEliminarAcampado(Acampado a) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar acampado'),
        content: Text('¿Seguro que quieres eliminar a ${a.nombreCompleto}?\nSe borrarán también todos sus gastos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _service.eliminarAcampado(_anioActual, a.id);
              await _cargar();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Detalle acampado ──────────────────────────────────────────

  void _mostrarDetalleAcampado(Acampado a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _DetalleAcampadoSheet(
        acampado: a,
        anio: _anioActual,
        service: _service,
        onUpdated: _cargar,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  Color _colorSaldo(double saldo) {
    if (saldo <= 0) return Colors.red.shade700;
    if (saldo < 5) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kiosko $_anioActual'),
        backgroundColor: const Color(0xFF1A5FA8),
        foregroundColor: Colors.white,
        actions: [
          // Botón sincronizar (solo si hay pendientes)
          if (_pendientesCount > 0)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: 'Sincronizar pendientes',
                  onPressed: _sincronizar,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: Colors.orange, shape: BoxShape.circle),
                    child: Text('$_pendientesCount',
                        style: const TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                ),
              ],
            ),

          // Botón PDF
          if (_cuaderno != null)
            _exportandoPDF
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    tooltip: 'Exportar PDF',
                    onPressed: _mostrarMenuPDF,
                  ),

          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cuaderno == null
              ? _buildVacio()
              : _buildLista(),
      floatingActionButton: _loading
          ? null
          : _cuaderno == null
              ? FloatingActionButton.extended(
                  onPressed: _mostrarDialogoNuevoCuaderno,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo cuaderno'),
                  backgroundColor: const Color(0xFF1A5FA8),
                )
              : FloatingActionButton(
                  onPressed: _mostrarDialogoAnadirAcampado,
                  backgroundColor: const Color(0xFF1A5FA8),
                  tooltip: 'Añadir acampado',
                  child: const Icon(Icons.person_add, color: Colors.white),
                ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.store, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No hay cuaderno para $_anioActual',
              style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Pulsa el botón para crear uno nuevo',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLista() {
    final acampados = _cuaderno!.acampados;
    return Column(
      children: [
        // Banner offline
        if (_offline)
          Container(
            color: Colors.orange.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Modo sin conexión — los cambios se guardan localmente',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        // Resumen global
        Container(
          color: const Color(0xFFE8F0FB),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Acampados', '${acampados.length}', Colors.blue),
              _buildStat(
                'Traído',
                '${acampados.fold(0.0, (s, a) => s + a.totalTraido).toStringAsFixed(2)}€',
                Colors.green,
              ),
              _buildStat(
                'Gastado',
                '${acampados.fold(0.0, (s, a) => s + a.totalGastado).toStringAsFixed(2)}€',
                Colors.red,
              ),
            ],
          ),
        ),

        // Lista
        Expanded(
          child: ListView.separated(
            itemCount: acampados.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, i) {
              final a = acampados[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1A5FA8),
                  child: Text(
                    a.nombre.isNotEmpty ? a.nombre[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(a.nombreCompleto,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Traído: ${a.totalTraido.toStringAsFixed(2)}€  ·  '
                  'Gastado: ${a.totalGastado.toStringAsFixed(2)}€',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Chip de saldo
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _colorSaldo(a.saldo).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${a.saldo.toStringAsFixed(2)}€',
                        style: TextStyle(
                          color: _colorSaldo(a.saldo),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // Botón eliminar acampado
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Colors.red.shade300, size: 20),
                      tooltip: 'Eliminar acampado',
                      onPressed: () => _confirmarEliminarAcampado(a),
                    ),
                  ],
                ),
                onTap: () => _mostrarDetalleAcampado(a),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  SHEET DE DETALLE
//  Mantiene estado local → no se cierra al añadir/eliminar gastos
// ══════════════════════════════════════════════════════════════════

class _DetalleAcampadoSheet extends StatefulWidget {
  final Acampado acampado;
  final int anio;
  final KioskoService service;
  final VoidCallback onUpdated;

  const _DetalleAcampadoSheet({
    required this.acampado,
    required this.anio,
    required this.service,
    required this.onUpdated,
  });

  @override
  State<_DetalleAcampadoSheet> createState() => _DetalleAcampadoSheetState();
}

class _DetalleAcampadoSheetState extends State<_DetalleAcampadoSheet> {
  final _diaController = TextEditingController();
  final _cantidadController = TextEditingController();
  bool _guardando = false;

  // Estado local — se actualiza sin cerrar el sheet
  late List<Gasto> _gastos;
  late double _totalTraido;

  @override
  void initState() {
    super.initState();
    _gastos = List.from(widget.acampado.gastos);
    _totalTraido = widget.acampado.totalTraido;
  }

  @override
  void dispose() {
    _diaController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  double get _totalGastado => _gastos.fold(0.0, (s, g) => s + g.cantidad);
  double get _saldo => _totalTraido - _totalGastado;

  // ── Añadir gasto — el sheet permanece abierto ─────────────────

  Future<void> _agregarGasto() async {
    final dia = int.tryParse(_diaController.text.trim());
    final cantidad = double.tryParse(
        _cantidadController.text.trim().replaceAll(',', '.'));

    if (dia == null || cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce un día y cantidad válidos')),
      );
      return;
    }

    setState(() => _guardando = true);
    await widget.service.registrarGasto(
        widget.anio, widget.acampado.id, dia, cantidad);

    // Actualizar estado local sin cerrar el sheet
    setState(() {
      _gastos.add(Gasto(dia: dia, cantidad: cantidad));
      _guardando = false;
    });

    _diaController.clear();
    _cantidadController.clear();

    // Notificar a la lista principal para que actualice el saldo
    widget.onUpdated();
  }

  // ── Eliminar gasto — el sheet permanece abierto ───────────────

  Future<void> _eliminarGasto(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text(
          'Día ${_gastos[index].dia} — ${_gastos[index].cantidad.toStringAsFixed(2)}€\n\n¿Seguro que quieres eliminarlo?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await widget.service.eliminarGasto(
        widget.anio, widget.acampado.id, index);

    // Actualizar estado local sin cerrar el sheet
    setState(() => _gastos.removeAt(index));
    widget.onUpdated();
  }

  // ── Editar dinero traído — el sheet permanece abierto ─────────

  Future<void> _editarDinero() async {
    final controller = TextEditingController(
        text: _totalTraido == 0 ? '' : _totalTraido.toStringAsFixed(2));

    final result = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dinero traído'),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Cantidad (€)',
            suffixText: '€',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A5FA8)),
            onPressed: () {
              final v = double.tryParse(
                  controller.text.trim().replaceAll(',', '.'));
              Navigator.pop(context, v);
            },
            child: const Text('Guardar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == null || result < 0) return;

    await widget.service.actualizarDinero(
        widget.anio, widget.acampado.id, result);

    // Actualizar estado local sin cerrar el sheet
    setState(() => _totalTraido = result);
    widget.onUpdated();
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorSaldo = _saldo < 0
        ? Colors.red.shade700
        : _saldo < 5
            ? Colors.orange.shade700
            : Colors.green.shade700;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: ListView(
          controller: scrollController,
          children: [
            // ── Cabecera ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.acampado.nombreCompleto,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Tarjetas de resumen ───────────────────────────
            Row(
              children: [
                _buildResumenChip(
                  'Traído',
                  '${_totalTraido.toStringAsFixed(2)}€',
                  Colors.blue,
                  onTap: _editarDinero,
                  editIcon: true,
                ),
                const SizedBox(width: 8),
                _buildResumenChip(
                  'Gastado',
                  '${_totalGastado.toStringAsFixed(2)}€',
                  Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildResumenChip(
                  'Saldo',
                  '${_saldo.toStringAsFixed(2)}€',
                  colorSaldo,
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),

            // ── Lista de gastos ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Gastos registrados',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${_gastos.length} gastos',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),

            if (_gastos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Sin gastos registrados',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              ...List.generate(_gastos.length, (i) {
                double acumulado = 0;
                for (int k = 0; k <= i; k++) {
                  acumulado += _gastos[k].cantidad;
                }
                final g = _gastos[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: i % 2 == 0
                        ? const Color(0xFFF7FAFD)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFE8F0FB),
                      child: Text(
                        'D${g.dia}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A5FA8)),
                      ),
                    ),
                    title: Text('${g.cantidad.toStringAsFixed(2)}€',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'Acumulado: ${acumulado.toStringAsFixed(2)}€',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Colors.red.shade300, size: 20),
                      tooltip: 'Eliminar gasto',
                      onPressed: () => _eliminarGasto(i),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 8),
            const Divider(),

            // ── Formulario añadir gasto ───────────────────────
            const Text('Añadir gasto',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _diaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Día',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _cantidadController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      suffixText: '€',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _agregarGasto(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _agregarGasto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A5FA8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Añadir'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenChip(
    String label,
    String value,
    Color color, {
    VoidCallback? onTap,
    bool editIcon = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600)),
                  if (editIcon) ...[
                    const SizedBox(width: 2),
                    Icon(Icons.edit, size: 10, color: color),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  DIÁLOGO NUEVO CUADERNO (lista de nombres)
// ══════════════════════════════════════════════════════════════════

class _NuevoCuadernoDialog extends StatefulWidget {
  final int anio;
  final Function(List<Map<String, dynamic>>) onCreado;

  const _NuevoCuadernoDialog({required this.anio, required this.onCreado});

  @override
  State<_NuevoCuadernoDialog> createState() => _NuevoCuadernoDialogState();
}

class _NuevoCuadernoDialogState extends State<_NuevoCuadernoDialog> {
  final _controller = TextEditingController();
  bool _creando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _crear() {
    final lineas = _controller.text
        .trim()
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lineas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe al menos un nombre')),
      );
      return;
    }

    final acampados = lineas.map((linea) {
      final partes = linea.split(' ');
      final nombre = partes.first;
      final apellidos =
          partes.length > 1 ? partes.sublist(1).join(' ') : '';
      return {
        'nombre': nombre,
        'apellidos': apellidos,
        'totalTraido': 0,
      };
    }).toList();

    setState(() => _creando = true);
    widget.onCreado(acampados);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nuevo cuaderno ${widget.anio}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Un acampado por línea:\nNombre Apellido1 Apellido2',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 12,
              autofocus: true,
              decoration: const InputDecoration(
                hintText:
                    'Adrián Salinero Romanillos\nAinhoa Hinojosa Torres\n...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _creando ? null : _crear,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A5FA8),
            foregroundColor: Colors.white,
          ),
          child: _creando
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Crear'),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  DIÁLOGO AÑADIR ACAMPADO (a cuaderno existente)
// ══════════════════════════════════════════════════════════════════

class _AnadirAcampadoDialog extends StatefulWidget {
  final Function(String nombre, String apellidos) onAnadido;

  const _AnadirAcampadoDialog({required this.onAnadido});

  @override
  State<_AnadirAcampadoDialog> createState() => _AnadirAcampadoDialogState();
}

class _AnadirAcampadoDialogState extends State<_AnadirAcampadoDialog> {
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final nombre = _nombreController.text.trim();
    final apellidos = _apellidosController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío')),
      );
      return;
    }

    widget.onAnadido(nombre, apellidos);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir acampado'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nombreController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apellidosController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Apellidos',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _confirmar(),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _confirmar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A5FA8),
            foregroundColor: Colors.white,
          ),
          child: const Text('Añadir'),
        ),
      ],
    );
  }
}