import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/punto.dart';
import '../services/punto_service.dart';
import 'seleccionar_ubicacion_screen.dart';

class ReportarPuntoScreen extends StatefulWidget {
  final Position? miUbicacion;

  const ReportarPuntoScreen({super.key, this.miUbicacion});

  @override
  State<ReportarPuntoScreen> createState() => _ReportarPuntoScreenState();
}

class _ReportarPuntoScreenState extends State<ReportarPuntoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _puntoService = PuntoService();

  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _horarioController = TextEditingController();
  final _descripcionController = TextEditingController();

  String _tipo = 'hidratacion';
  bool _guardando = false;
  LatLng? _ubicacionSeleccionada;

  @override
  void initState() {
    super.initState();
    final ubicacion = widget.miUbicacion;
    if (ubicacion != null) {
      _ubicacionSeleccionada = LatLng(ubicacion.latitude, ubicacion.longitude);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _horarioController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ubicacionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la ubicación en el mapa.')),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final punto = Punto(
        id: '',
        nombre: _nombreController.text.trim(),
        tipo: _tipo,
        direccion: _direccionController.text.trim(),
        telefono: _telefonoController.text.trim(),
        lat: _ubicacionSeleccionada!.latitude,
        lng: _ubicacionSeleccionada!.longitude,
        horario: _horarioController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        estado: 'pendiente',
        confianza: 'reciente',
        ultimaConfirmacion: null,
        confirmaciones: 0,
        votosAbiertoHoy: 0,
        votosCerradoHoy: 0,
        diaVotacion: '',
        fuente: 'comunidad',
        direccionVerificada: false,
      );

      await _puntoService.reportarPuntoComunitario(punto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gracias, el punto quedó pendiente de revisión.'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  String? _requerido(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es necesario';
    }
    return null;
  }

  Future<void> _seleccionarUbicacion() async {
    const centroMexicali = LatLng(32.6245, -115.4523);
    final seleccion = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => SeleccionarUbicacionScreen(
          ubicacionInicial: _ubicacionSeleccionada ?? centroMexicali,
        ),
      ),
    );

    if (seleccion != null && mounted) {
      setState(() => _ubicacionSeleccionada = seleccion);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportar punto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Ayuda a ubicar agua, sombra, aire o refugio para calor extremo.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del lugar',
                prefixIcon: Icon(Icons.storefront),
              ),
              validator: _requerido,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              decoration: const InputDecoration(
                labelText: 'Qué ofrece',
                prefixIcon: Icon(Icons.volunteer_activism),
              ),
              items: const [
                DropdownMenuItem(value: 'hidratacion', child: Text('Agua')),
                DropdownMenuItem(value: 'sombra', child: Text('Sombra')),
                DropdownMenuItem(
                  value: 'aire',
                  child: Text('Aire acondicionado'),
                ),
                DropdownMenuItem(value: 'refugio', child: Text('Refugio')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _tipo = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _direccionController,
              decoration: const InputDecoration(
                labelText: 'Dirección o referencia',
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: _requerido,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _seleccionarUbicacion,
              icon: const Icon(Icons.map),
              label: Text(
                _ubicacionSeleccionada == null
                    ? 'Seleccionar ubicación en mapa'
                    : 'Cambiar ubicación seleccionada',
              ),
            ),
            if (_ubicacionSeleccionada != null) ...[
              const SizedBox(height: 6),
              Text(
                'Ubicación seleccionada',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _horarioController,
              decoration: const InputDecoration(
                labelText: 'Horario',
                hintText: 'Ej. 4:00 p.m. a 8:00 a.m. o 24 horas',
                prefixIcon: Icon(Icons.schedule),
              ),
              validator: _requerido,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                hintText: 'Opcional',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Detalles',
                hintText: 'Ej. agua fría, sombra, sala con aire, baño',
                prefixIcon: Icon(Icons.notes),
              ),
              minLines: 3,
              maxLines: 5,
              validator: _requerido,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_location_alt),
              label: Text(_guardando ? 'Guardando...' : 'Enviar punto'),
            ),
          ],
        ),
      ),
    );
  }
}
