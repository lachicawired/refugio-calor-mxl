import 'package:flutter/material.dart';
import '../models/punto.dart';
import '../services/punto_service.dart';

// Esta pantalla es temporal: solo sirve para cargar los primeros
// puntos reales a Firestore sin tener que hacerlo a mano en la consola.
// Cuando ya tengas tus puntos cargados, puedes borrar este archivo.
class SeedScreen extends StatefulWidget {
  const SeedScreen({super.key});

  @override
  State<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<SeedScreen> {
  final _puntoService = PuntoService();
  bool _cargando = false;
  String _mensaje = '';

  // Aquí defines todos los puntos que quieres cargar de un jalón.
  // Agrega o quita objetos Punto de esta lista según necesites.
  final List<Punto> _puntosIniciales = [
    Punto(
      id: '',
      nombre: 'Albergue El Peregrino',
      tipo: 'refugio',
      direccion: 'Calzada de Los Presidentes, casi esq. Ciudad Victoria',
      telefono: '686 233 5281',
      lat: 32.6508689,
      lng: -115.484229,
      horario: '24 horas',
      descripcion: 'Refugio con hidratación y atención básica.',
      estado: 'abierto',
      confianza: 'oficial',
      ultimaConfirmacion: DateTime.now(),
      confirmaciones: 1,
      votosAbiertoHoy: 0,
      votosCerradoHoy: 0,
      diaVotacion: '',
      fuente: 'manual',
      direccionVerificada: true,
    ),
    Punto(
      id: '',
      nombre: 'Módulo de hidratación - Parque El Mariachi',
      tipo: 'hidratacion',
      direccion: 'Parque El Mariachi, Centro Histórico de Mexicali',
      telefono: '',
      lat: 32.6584,
      lng: -115.486955,
      horario: 'Por confirmar',
      descripcion:
          'Espacio con agua, suero oral y atención médica básica para migrantes y personas en situación de calle.',
      estado: 'abierto',
      confianza: 'comunidad',
      ultimaConfirmacion: DateTime.now(),
      confirmaciones: 1,
      votosAbiertoHoy: 0,
      votosCerradoHoy: 0,
      diaVotacion: '',
      fuente: 'manual',
      direccionVerificada: true,
    ),
    Punto(
      id: '',
      nombre: 'Albergue Casa Betania',
      tipo: 'refugio',
      direccion:
          'Av. Lago Hudson #2408, Col. Xochimilco, C.P. 21380, Mexicali, B.C.',
      telefono: '686 580 0687',
      lat: 32.6071543,
      lng: -115.4437071,
      horario: 'Por confirmar',
      descripcion: 'Albergue A.C. Facebook: Albergue Casa Betania, A.C.',
      estado: 'abierto',
      confianza: 'comunidad',
      ultimaConfirmacion: DateTime.now(),
      confirmaciones: 1,
      votosAbiertoHoy: 0,
      votosCerradoHoy: 0,
      diaVotacion: '',
      fuente: 'manual',
      direccionVerificada: true,
    ),
  ];

  Future<void> _cargarPuntos() async {
    setState(() {
      _cargando = true;
      _mensaje = '';
    });

    int exitosos = 0;

    for (final punto in _puntosIniciales) {
      try {
        await _puntoService.crearPunto(punto);
        exitosos++;
      } catch (e) {
        setState(() => _mensaje += '\nError con ${punto.nombre}: $e');
      }
    }

    setState(() {
      _cargando = false;
      _mensaje =
          'Se cargaron $exitosos de ${_puntosIniciales.length} puntos.$_mensaje';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cargar puntos iniciales')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Puntos listos para cargar: ${_puntosIniciales.length}'),
            const SizedBox(height: 16),
            if (_cargando)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _cargarPuntos,
                child: const Text('Cargar puntos a Firestore'),
              ),
            const SizedBox(height: 16),
            Text(_mensaje),
          ],
        ),
      ),
    );
  }
}
