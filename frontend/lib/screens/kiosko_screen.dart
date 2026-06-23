import 'package:flutter/material.dart';
import '../../services/kiosko_service.dart';
import 'acampado_detalle_screen.dart';
import 'nuevo_cuaderno_screen.dart';

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
      final pendientes = await _service._getPendingOps(_anioActual);
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
    if (n > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$n operaciones sincronizadas ✓')),
      );
      await _cargar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin conexión o nada pendiente')),
      );
    }
  }

  Color _colorSaldo(double saldo) {
    if (saldo <= 0) return Colors.red.shade700;
    if (saldo < 5) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kiosko ${_anioActual}'),
        backgroundColor: const Color(0xFF1A5FA8),
        foregroundColor: Colors.white,
        actions: [
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
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white)),
                  ),
                )
              ],
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cuaderno == null
              ? _buildVacio()
              : _buildLista(),
      floatingActionButton: _cuaderno == null
          ? FloatingActionButton.extended(
              onPressed: _irANuevoCuaderno,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo cuaderno'),
              backgroundColor: const Color(0xFF1A5FA8),
            )
          : null,
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.store, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No hay cuaderno para $_anioActual',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pulsa el botón para crear uno nuevo',
            style: TextStyle(color: Colors.grey),
          ),
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
                Text('Modo sin conexión — datos guardados localmente',
                    style: TextStyle(color: Colors.orange, fontSize: 12)),
              ],
            ),
          ),

        // Resumen global
        Container(
          color: const Color(0xFFE8F0FB),
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Acampados', '${acampados.length}', Colors.blue),
              _buildStat(
                'Total traído',
                '${acampados.fold(0.0, (s, a) => s + a.totalTraido).toStringAsFixed(2)}€',
                Colors.green,
              ),
              _buildStat(
                'Total gastado',
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
                    'Traído: ${a.totalTraido.toStringAsFixed(2)}€  ·  Gastado: ${a.totalGastado.toStringAsFixed(2)}€'),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AcampadoDetalleScreen(
                      acampado: a,
                      anio: _anioActual,
                      onUpdated: _cargar,
                    ),
                  ),
                ),
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
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  void _irANuevoCuaderno() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NuevoCuadernoScreen(
          anio: _anioActual,
          onCreado: _cargar,
        ),
      ),
    );
  }
}
