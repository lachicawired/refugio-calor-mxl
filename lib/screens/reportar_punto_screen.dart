import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/punto.dart';
import '../services/punto_service.dart';

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
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  String _tipo = 'hidratacion';
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final ubicacion = widget.miUbicacion;
    if (ubicacion != null) {
      _latController.text = ubicacion.latitude.toStringAsFixed(6);
      _lngController.text = ubicacion.longitude.toStringAsFixed(6);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _horarioController.dispose();
    _descripcionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final punto = Punto(
        id: '',
        nombre: _nombreController.text.trim(),
        tipo: _tipo,
        direccion: _direccionController.text.trim(),
        telefono: _telefonoController.text.trim(),
        lat: double.parse(_latController.text.trim()),
        lng: double.parse(_lngController.text.trim()),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el punto: $e')),
        );
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

  String? _coordenada(String? value) {
    final requerido = _requerido(value);
    if (requerido != null) return requerido;

    if (double.tryParse(value!.trim()) == null) {
      return 'Usa un número válido';
    }
    return null;
  }

  void _usarMiUbicacion() {
    final ubicacion = widget.miUbicacion;
    if (ubicacion == null) return;

    setState(() {
      _latController.text = ubicacion.latitude.toStringAsFixed(6);
      _lngController.text = ubicacion.longitude.toStringAsFixed(6);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ubicacionDisponible = widget.miUbicacion != null;

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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    decoration: const InputDecoration(labelText: 'Latitud'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: _coordenada,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    decoration: const InputDecoration(labelText: 'Longitud'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: _coordenada,
                  ),
                ),
              ],
            ),
            if (ubicacionDisponible) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _usarMiUbicacion,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Usar mi ubicación actual'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _horarioController,
              decoration: const InputDecoration(
                labelText: 'Horario',
                hintText: 'Ej. 8:00 a 18:00 o Por confirmar',
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
