import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SeleccionarUbicacionScreen extends StatefulWidget {
  final LatLng ubicacionInicial;

  const SeleccionarUbicacionScreen({super.key, required this.ubicacionInicial});

  @override
  State<SeleccionarUbicacionScreen> createState() =>
      _SeleccionarUbicacionScreenState();
}

class _SeleccionarUbicacionScreenState
    extends State<SeleccionarUbicacionScreen> {
  late LatLng _seleccion;

  @override
  void initState() {
    super.initState();
    _seleccion = widget.ubicacionInicial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar ubicación')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: widget.ubicacionInicial,
          initialZoom: 15,
          onTap: (tapPosition, point) {
            setState(() => _seleccion = point);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.refugio_calor',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _seleccion,
                width: 44,
                height: 44,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 44,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context, _seleccion),
        icon: const Icon(Icons.check),
        label: const Text('Usar ubicación'),
      ),
    );
  }
}
