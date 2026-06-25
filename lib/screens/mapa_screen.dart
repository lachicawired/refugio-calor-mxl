import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/punto.dart';
import '../services/punto_service.dart';
import '../services/ubicacion_service.dart';
import '../theme/theme_controller.dart';
import 'admin_panel_screen.dart';
import 'detalle_punto_screen.dart';
import 'reportar_punto_screen.dart';
import '../services/admin_service.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final _puntoService = PuntoService();
  final _adminService = AdminService();

  String? _filtroTipo;
  Position? _miUbicacion;
  late Future<List<Punto>> _puntosFuture;
  bool _esAdmin = false;

  static const _centroMexicali = LatLng(32.6245, -115.4523);

  @override
  void initState() {
    super.initState();
    _puntosFuture = _puntoService.obtenerPuntosMapa();
    _cargarUbicacion();
    _verificarAdmin();
  }

  Future<void> _cargarUbicacion() async {
    final ubicacion = await UbicacionService.obtenerUbicacionActual();
    if (mounted) {
      setState(() => _miUbicacion = ubicacion);
    }
  }

  Future<void> _verificarAdmin() async {
    final esAdmin = await _adminService.esAdminActual();
    if (mounted) {
      setState(() => _esAdmin = esAdmin);
    }
  }

  Future<void> _recargarPuntos() async {
    setState(() {
      _puntosFuture = _puntoService.obtenerPuntosMapa();
    });
    await _puntosFuture;
  }

  String _textoConfianza(Punto punto) {
    if (punto.oculto ||
        punto.estado == 'cerrado' ||
        punto.confianza == 'cerrado') {
      return 'cerrado';
    }
    if (punto.verificadoOficialmente ||
        punto.confianza == 'oficial' ||
        punto.confianza == 'verificado_oficialmente') {
      return 'oficial';
    }
    if (punto.aprobado || punto.confianza == 'comunidad') {
      return 'comunidad';
    }
    return 'pendiente';
  }

  Color _colorPorConfianza(Punto punto) {
    switch (_textoConfianza(punto)) {
      case 'oficial':
      case 'comunidad':
        return Colors.green;
      case 'cerrado':
        return Colors.red;
      case 'pendiente':
      default:
        return Colors.amber.shade700;
    }
  }

  IconData _iconoPorTipo(String tipo) {
    switch (tipo) {
      case 'hidratacion':
        return Icons.water_drop;
      case 'sombra':
        return Icons.park;
      case 'aire':
        return Icons.ac_unit;
      case 'refugio':
        return Icons.home;
      default:
        return Icons.location_on;
    }
  }

  void _abrirReportePunto() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportarPuntoScreen(miUbicacion: _miUbicacion),
      ),
    );
  }

  Future<void> _abrirAdmin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminEntryScreen()),
    );
    await _verificarAdmin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: _abrirAdmin,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department),
              SizedBox(width: 8),
              Text('Refugio de Calor MXL'),
            ],
          ),
        ),
        actions: [
          if (_esAdmin)
            IconButton(
              tooltip: 'Panel admin',
              onPressed: _abrirAdmin,
              icon: const Icon(Icons.admin_panel_settings),
            ),
          IconButton(
            tooltip: 'Recargar puntos',
            onPressed: _recargarPuntos,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Cambiar tema',
            onPressed: ThemeController.toggle,
            icon: Icon(
              ThemeController.isDark(context)
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirReportePunto,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Reportar punto'),
      ),
      body: Column(
        children: [
          const _BrandBanner(),
          _buildFiltros(),
          Expanded(
            child: FutureBuilder<List<Punto>>(
              future: _puntosFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final puntos = snapshot.data!;
                final puntosFiltrados = _filtroTipo == null
                    ? puntos
                    : puntos.where((p) => p.tipo == _filtroTipo).toList();

                return FlutterMap(
                  options: const MapOptions(
                    initialCenter: _centroMexicali,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.refugio_calor',
                    ),
                    MarkerLayer(
                      markers: [
                        ...puntosFiltrados.map((punto) {
                          final color = _colorPorConfianza(punto);

                          return Marker(
                            point: LatLng(punto.lat, punto.lng),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetallePuntoScreen(
                                      punto: punto,
                                      miUbicacion: _miUbicacion,
                                    ),
                                  ),
                                );
                                if (context.mounted) {
                                  _recargarPuntos();
                                }
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: color,
                                    size: 40,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Icon(
                                      _iconoPorTipo(punto.tipo),
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        if (_miUbicacion != null)
                          Marker(
                            point: LatLng(
                              _miUbicacion!.latitude,
                              _miUbicacion!.longitude,
                            ),
                            width: 24,
                            height: 24,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.30),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    final tipos = {
      null: 'Todos',
      'hidratacion': 'Agua',
      'sombra': 'Sombra',
      'aire': 'Aire',
      'refugio': 'Refugio',
    };

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: tipos.entries.map((entry) {
            final seleccionado = _filtroTipo == entry.key;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: seleccionado,
                onSelected: (_) {
                  setState(() => _filtroTipo = entry.key);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _BrandBanner extends StatelessWidget {
  const _BrandBanner();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.shield, color: colors.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mapa comunitario contra calor extremo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Agua, sombra, aire y refugios en Mexicali',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
