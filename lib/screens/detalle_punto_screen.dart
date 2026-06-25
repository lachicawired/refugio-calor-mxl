import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/punto.dart';
import '../models/reporte.dart';
import '../services/device_id_service.dart';
import '../services/horario_service.dart';
import '../services/punto_service.dart';
import '../services/ubicacion_service.dart';
import 'reportar_punto_screen.dart';

class DetallePuntoScreen extends StatefulWidget {
  final Punto punto;
  final Position? miUbicacion;

  const DetallePuntoScreen({super.key, required this.punto, this.miUbicacion});

  @override
  State<DetallePuntoScreen> createState() => _DetallePuntoScreenState();
}

class _DetallePuntoScreenState extends State<DetallePuntoScreen> {
  final _puntoService = PuntoService();
  bool _enviandoReporte = false;
  late Future<Punto> _puntoFuture;

  @override
  void initState() {
    super.initState();
    _puntoFuture = _puntoService.obtenerPuntoCombinado(widget.punto);
  }

  Future<void> _enviarReporte(
    String tipoReporte, {
    String comentario = '',
  }) async {
    setState(() => _enviandoReporte = true);

    try {
      final deviceId = await DeviceIdService.obtenerDeviceId();
      final reporte = Reporte(
        id: '',
        puntoId: widget.punto.id,
        tipoReporte: tipoReporte,
        creadoEn: DateTime.now(),
        deviceId: deviceId,
        comentario: comentario,
      );

      await _puntoService.registrarReporte(reporte);

      if (mounted) {
        setState(() {
          _puntoFuture = _puntoService.obtenerPuntoCombinado(widget.punto);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_mensajeReporte(tipoReporte))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo enviar el reporte: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enviandoReporte = false);
      }
    }
  }

  Future<void> _mostrarFormularioCambio() async {
    final controller = TextEditingController();

    final comentario = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reportar cambio',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Cuéntanos qué cambió: horario, teléfono, ubicación, servicios o disponibilidad.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Detalle del cambio',
                  prefixIcon: Icon(Icons.edit_location_alt),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    final texto = controller.text.trim();
                    if (texto.isNotEmpty) {
                      Navigator.pop(context, texto);
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Enviar cambio'),
                ),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (comentario != null && comentario.trim().isNotEmpty) {
      await _enviarReporte('reportar_cambio', comentario: comentario.trim());
    }
  }

  String _mensajeReporte(String tipoReporte) {
    switch (tipoReporte) {
      case 'confirmado_abierto':
        return 'Gracias, tu voto de hoy quedó como abierto.';
      case 'reportado_cerrado':
        return 'Gracias, tu voto de hoy quedó como cerrado.';
      case 'reportar_cambio':
        return 'Gracias, registramos que este punto necesita revisión.';
      default:
        return 'Gracias, tu reporte ayuda a la comunidad.';
    }
  }

  Color _colorPorEstado(String estado) {
    switch (estado) {
      case 'abierto':
        return Colors.green;
      case 'pendiente':
        return Colors.amber.shade700;
      case 'cerrado':
        return Colors.red;
      default:
        return Colors.grey;
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
        return Icons.place;
    }
  }

  String _tipoLegible(String tipo) {
    switch (tipo) {
      case 'hidratacion':
        return 'Agua';
      case 'sombra':
        return 'Sombra';
      case 'aire':
        return 'Aire acondicionado';
      case 'refugio':
        return 'Refugio';
      default:
        return 'Punto seguro';
    }
  }

  String _estadoLegible(String estado) {
    switch (estado) {
      case 'abierto':
        return 'Confirmado abierto';
      case 'pendiente':
        return 'Pendiente de revisar';
      case 'cerrado':
        return 'Cerrado o no disponible';
      default:
        return 'Sin verificar';
    }
  }

  String _confianzaLegible(String confianza) {
    switch (confianza) {
      case 'oficial':
        return 'Verificado oficialmente';
      case 'comunidad':
        return 'Verificado por comunidad';
      case 'reciente':
        return 'Reportado recientemente';
      case 'cerrado':
        return 'Cerrado/no disponible';
      default:
        return 'Pendiente de revisar';
    }
  }

  String _fechaLegible(DateTime? fecha) {
    if (fecha == null) return 'Sin confirmaciones todavía';

    final diferencia = DateTime.now().difference(fecha);

    if (diferencia.inMinutes < 1) return 'Hace un momento';
    if (diferencia.inHours < 1) return 'Hace ${diferencia.inMinutes} min';
    if (diferencia.inDays < 1) return 'Hace ${diferencia.inHours} h';
    if (diferencia.inDays == 1) return 'Ayer';

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  void _abrirReportePunto() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportarPuntoScreen(miUbicacion: widget.miUbicacion),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Punto>(
      future: _puntoFuture,
      initialData: widget.punto,
      builder: (context, snapshot) {
        final punto = snapshot.data ?? widget.punto;

        return Scaffold(
          appBar: AppBar(title: Text(punto.nombre)),
          body: _buildContenido(punto),
        );
      },
    );
  }

  Widget _buildContenido(Punto punto) {
    final ubicacion = widget.miUbicacion;
    final estadoColor = _colorPorEstado(punto.estado);

    String? distanciaTexto;
    if (ubicacion != null) {
      distanciaTexto = UbicacionService.calcularDistanciaFormateada(
        ubicacion.latitude,
        ubicacion.longitude,
        punto.lat,
        punto.lng,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: Icon(_iconoPorTipo(punto.tipo), size: 18),
              label: Text(_tipoLegible(punto.tipo)),
            ),
            Chip(
              backgroundColor: estadoColor.withValues(alpha: 0.14),
              side: BorderSide(color: estadoColor),
              label: Text(
                _estadoLegible(punto.estado),
                style: TextStyle(
                  color: estadoColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          punto.nombre,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (distanciaTexto != null) ...[
          _InfoRow(
            icon: Icons.near_me,
            label: 'Distancia',
            value: 'Aprox. $distanciaTexto de tu ubicación',
            color: Colors.blue,
          ),
          const SizedBox(height: 10),
        ],
        _InfoRow(
          icon: Icons.location_on,
          label: 'Dirección',
          value: punto.direccion,
        ),
        if (!punto.direccionVerificada) ...[
          const SizedBox(height: 8),
          const _Notice(
            icon: Icons.warning_amber,
            text: 'Ubicación aproximada, dirección exacta sin confirmar.',
            color: Colors.orange,
          ),
        ],
        const SizedBox(height: 16),
        _InfoRow(
          icon: Icons.schedule,
          label: 'Horario',
          value: punto.horario.isEmpty ? 'Por confirmar' : punto.horario,
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.access_time_filled,
          label: 'Ahora',
          value: HorarioService.textoCombinado(
            horario: punto.horario,
            estadoComunitario: punto.estado,
          ),
          color: estadoColor,
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.phone,
          label: 'Teléfono',
          value: punto.telefono.isEmpty ? 'No disponible' : punto.telefono,
        ),
        const SizedBox(height: 20),
        _SectionTitle('Qué ofrece'),
        const SizedBox(height: 8),
        Text(
          punto.descripcion.isEmpty
              ? 'Información pendiente de confirmar por la comunidad.'
              : punto.descripcion,
          style: const TextStyle(fontSize: 15, height: 1.35),
        ),
        const SizedBox(height: 20),
        _SectionTitle('Confianza comunitaria'),
        const SizedBox(height: 8),
        _TrustPanel(
          confianza: _confianzaLegible(punto.confianza),
          ultimaConfirmacion: _fechaLegible(punto.ultimaConfirmacion),
          votosAbiertoHoy: punto.votosAbiertoHoy,
          votosCerradoHoy: punto.votosCerradoHoy,
          color: estadoColor,
        ),
        const SizedBox(height: 24),
        if (_enviandoReporte)
          const Center(child: CircularProgressIndicator())
        else ...[
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _enviarReporte('confirmado_abierto'),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Sigue abierto'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _enviarReporte('reportado_cerrado'),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Está cerrado'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _mostrarFormularioCambio,
            icon: const Icon(Icons.edit_location_alt),
            label: const Text('Reportar cambio'),
          ),
          TextButton.icon(
            onPressed: _abrirReportePunto,
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Reportar punto nuevo'),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: effectiveColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Notice({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _TrustPanel extends StatelessWidget {
  final String confianza;
  final String ultimaConfirmacion;
  final int votosAbiertoHoy;
  final int votosCerradoHoy;
  final Color color;

  const _TrustPanel({
    required this.confianza,
    required this.ultimaConfirmacion,
    required this.votosAbiertoHoy,
    required this.votosCerradoHoy,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _TrustRow(
            icon: Icons.verified_user,
            label: 'Estado de confianza',
            value: confianza,
          ),
          const Divider(height: 20),
          _TrustRow(
            icon: Icons.update,
            label: 'Última confirmación',
            value: ultimaConfirmacion,
          ),
          const Divider(height: 20),
          _TrustRow(
            icon: Icons.groups,
            label: 'Votos de hoy',
            value: '$votosAbiertoHoy abierto / $votosCerradoHoy cerrado',
          ),
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TrustRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
